"""Auth API Routes — تسجيل الدخول والتسجيل وإدارة التوكنات."""
from __future__ import annotations

import hashlib
import hmac
import logging
import os
import secrets
import smtplib
import time
import uuid
from email.message import EmailMessage
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, Field

from security.auth.api_key_manager import get_api_key_manager
from api.v1.auth.social import (
    SocialAuthError,
    verify_facebook_access_token,
    verify_google_id_token,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["Authentication"])

JWT_SECRET = os.getenv("JWT_SECRET", "hajeen-change-me-in-production-secret-key")


# ── Schemas ───────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: str = Field(..., min_length=5)
    password: str = Field(..., min_length=8)
    tenant_id: str = Field(default="default")
    roles: List[str] = Field(default_factory=lambda: ["user"])


class LoginRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: str
    tenant_id: str = "default"


class SocialLoginRequest(BaseModel):
    token: str = Field(..., min_length=20, max_length=8192)
    tenant_id: str = "default"


class RefreshRequest(BaseModel):
    refresh_token: str


class VerifyEmailRequest(BaseModel):
    email: str = Field(..., min_length=5)
    code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class ResendVerificationRequest(BaseModel):
    email: str = Field(..., min_length=5)


class RevokeRequest(BaseModel):
    token: str


class CreateAPIKeyRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    roles: List[str] = Field(default=["user"]) # Changed from scopes to roles for consistency with RBAC
    expires_in_days: Optional[int] = Field(None, ge=1, le=365)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
    roles: List[str]
    tenant_id: str
    user: Dict[str, Any]


# ── In-memory user store (يُستبدل بـ PostgreSQL في الإنتاج) ──────────────────

_USERS: Dict[str, Dict[str, Any]] = {
    "admin": {
        "user_id": "usr_admin",
        "username": "admin",
        "email": "admin@hajeen.ai",
        "password_hash": "__admin_placeholder__",
        "roles": ["superadmin"],
        "tenant_id": "default",
        "active": True,
    }
}


def _hash_password(password: str) -> str:
    import hashlib
    salt = os.getenv("PASSWORD_SALT", "hajeen-salt-change-me")
    return hashlib.sha256(f"{salt}{password}".encode()).hexdigest()


def _verify_password(password: str, stored_hash: str) -> bool:
    if stored_hash == "__admin_placeholder__":
        return password == os.getenv("ADMIN_PASSWORD", "HajeenAdmin2024!")
    return hmac.compare_digest(_hash_password(password), stored_hash)


def _hash_verification_code(code: str) -> str:
    salt = os.getenv("VERIFICATION_CODE_SALT", os.getenv("PASSWORD_SALT", "hajeen-salt-change-me"))
    return hashlib.sha256(f"{salt}:{code}".encode()).hexdigest()


def _new_verification_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def _smtp_configured() -> bool:
    return all(os.getenv(key) for key in ("SMTP_HOST", "SMTP_PORT", "SMTP_USERNAME", "SMTP_PASSWORD", "SMTP_FROM_EMAIL"))


def _send_verification_email(email: str, code: str) -> None:
    if not _smtp_configured():
        raise RuntimeError("SMTP configuration is incomplete")
    message = EmailMessage()
    message["Subject"] = "رمز التحقق من البريد الإلكتروني - Hajeen AI"
    message["From"] = os.environ["SMTP_FROM_EMAIL"]
    message["To"] = email
    message.set_content(
        "مرحباً في Hajeen AI،\\n\\n"
        f"رمز التحقق الخاص بك هو: {code}\\n"
        "يظل الرمز صالحاً لمدة 10 دقائق. إذا لم تطلب إنشاء الحساب فتجاهل هذه الرسالة."
    )
    host = os.environ["SMTP_HOST"]
    port = int(os.environ.get("SMTP_PORT", "587"))
    use_tls = os.getenv("SMTP_USE_TLS", "true").lower() not in {"0", "false", "no"}
    with smtplib.SMTP(host, port, timeout=15) as smtp:
        smtp.ehlo()
        if use_tls:
            smtp.starttls()
            smtp.ehlo()
        smtp.login(os.environ["SMTP_USERNAME"], os.environ["SMTP_PASSWORD"])
        smtp.send_message(message)


def _issue_verification(user: Dict[str, Any]) -> None:
    code = _new_verification_code()
    user["verification_code_hash"] = _hash_verification_code(code)
    user["verification_expires_at"] = time.time() + 600
    user["verification_attempts"] = 0
    user["verification_sent_at"] = time.time()
    _send_verification_email(user["email"], code)


def _find_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    normalized = email.strip().lower()
    return next((candidate for candidate in _USERS.values() if isinstance(candidate.get("email"), str) and candidate["email"].lower() == normalized), None)


def _get_jwt_auth():
    import os

    from security.auth.jwt_auth import JWTAuthenticator
    from security.auth.revoked_tokens import get_revoked_token_store
    return JWTAuthenticator(secret=os.getenv("JWT_SECRET", JWT_SECRET), revoked_store=get_revoked_token_store())


def _username_for_email(email: str) -> str:
    base = email.split("@", 1)[0].strip() or "user"
    username = base[:50]
    suffix = 1
    while username in _USERS:
        suffix += 1
        suffix_text = str(suffix)
        username = f"{base[:50-len(suffix_text)-1]}_{suffix_text}"
    return username


def _issue_token_response(user: Dict[str, Any]) -> TokenResponse:
    jwt = _get_jwt_auth()
    access_token = jwt.issue_token(
        user_id=user["user_id"], tenant_id=user["tenant_id"], roles=user["roles"], token_type="access"
    )
    refresh_token = jwt.issue_token(
        user_id=user["user_id"], tenant_id=user["tenant_id"], roles=user["roles"], token_type="refresh"
    )
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=3600,
        user_id=user["user_id"],
        roles=user["roles"],
        tenant_id=user["tenant_id"],
        user={
            "id": user["user_id"],
            "name": user.get("name", user["username"]),
            "email": user["email"],
            "username": user["username"],
        },
    )


def _upsert_social_user(identity: Dict[str, Any], tenant_id: str) -> Dict[str, Any]:
    provider = identity["provider"]
    provider_sub = identity["provider_sub"]
    email = identity["email"]

    # First match the immutable provider subject. This prevents account takeover
    # when a provider changes a display name or email address.
    user = next(
        (
            candidate
            for candidate in _USERS.values()
            if candidate.get("social_identities", {}).get(provider) == provider_sub
        ),
        None,
    )
    if user is None:
        # Linking by email is allowed only after the provider verifier has
        # established a verified email claim.
        user = next(
            (candidate for candidate in _USERS.values() if candidate.get("email", "").lower() == email),
            None,
        )
    if user is None:
        username = _username_for_email(email)
        user = {
            "user_id": f"usr_{uuid.uuid4().hex[:12]}",
            "username": username,
            "name": identity["name"],
            "email": email,
            "password_hash": "__social_only__",
            "roles": ["user"],
            "tenant_id": tenant_id,
            "active": True,
            "created_at": time.time(),
            "social_identities": {},
        }
        _USERS[username] = user
    elif not user.get("active"):
        raise SocialAuthError("الحساب غير نشط")

    identities = user.setdefault("social_identities", {})
    existing_subject = identities.get(provider)
    if existing_subject and existing_subject != provider_sub:
        raise SocialAuthError("مزود الحساب مرتبط بهوية مختلفة")
    identities[provider] = provider_sub
    if not user.get("name"):
        user["name"] = identity["name"]
    return user


# ── POST /auth/register ───────────────────────────────────────────────────────

@router.post("/register", summary="تسجيل مستخدم جديد", status_code=201)
async def register(body: RegisterRequest) -> Dict[str, Any]:
    username = (body.username or body.email.split("@", 1)[0]).strip()
    if username in _USERS:
        raise HTTPException(status_code=400, detail="اسم المستخدم موجود بالفعل")
    if _find_user_by_email(body.email):
        raise HTTPException(status_code=400, detail="البريد الإلكتروني مستخدم بالفعل")

    user_id = f"usr_{uuid.uuid4().hex[:12]}"
    user = {
        "user_id": user_id,
        "username": username,
        "name": body.name or username,
        "email": body.email.strip().lower(),
        "password_hash": _hash_password(body.password),
        "roles": body.roles,
        "tenant_id": body.tenant_id,
        "active": False,
        "email_verified": False,
        "created_at": time.time(),
    }
    _USERS[username] = user
    try:
        _issue_verification(user)
    except Exception as exc:
        _USERS.pop(username, None)
        logger.exception("Verification email delivery failed for %s", user["email"])
        raise HTTPException(status_code=503, detail="تعذر إرسال رمز التحقق حالياً") from exc

    logger.info("New pending user registered: %s (tenant=%s)", username, body.tenant_id)
    return {
        "success": True,
        "pending_verification": True,
        "user_id": user_id,
        "username": username,
        "email": user["email"],
        "message": "تم إنشاء الحساب. تحقق من بريدك الإلكتروني لإكمال التسجيل.",
    }


@router.post("/verify-email", summary="تأكيد البريد الإلكتروني")
async def verify_email(body: VerifyEmailRequest) -> Dict[str, Any]:
    user = _find_user_by_email(body.email)
    if not user or user.get("email_verified"):
        raise HTTPException(status_code=400, detail="رمز التحقق غير صالح")
    if user.get("verification_attempts", 0) >= 5:
        raise HTTPException(status_code=429, detail="تم تجاوز عدد المحاولات. أعد إرسال رمزاً جديداً.")
    user["verification_attempts"] = user.get("verification_attempts", 0) + 1
    if time.time() > user.get("verification_expires_at", 0):
        raise HTTPException(status_code=400, detail="انتهت صلاحية رمز التحقق")
    expected = user.get("verification_code_hash", "")
    if not expected or not hmac.compare_digest(expected, _hash_verification_code(body.code)):
        raise HTTPException(status_code=400, detail="رمز التحقق غير صحيح")
    user["email_verified"] = True
    user["active"] = True
    user.pop("verification_code_hash", None)
    user.pop("verification_expires_at", None)
    user.pop("verification_attempts", None)
    return {"success": True, "email_verified": True, "message": "تم تأكيد البريد الإلكتروني بنجاح"}


@router.post("/resend-verification", summary="إعادة إرسال رمز التحقق")
async def resend_verification(body: ResendVerificationRequest) -> Dict[str, Any]:
    user = _find_user_by_email(body.email)
    if not user or user.get("email_verified"):
        return {"success": True, "message": "إذا كان الحساب بحاجة إلى تحقق فسيتم إرسال رمز جديد"}
    last_sent = user.get("verification_sent_at", 0)
    if time.time() - last_sent < 60:
        raise HTTPException(status_code=429, detail="انتظر دقيقة قبل طلب رمز جديد")
    try:
        _issue_verification(user)
    except Exception as exc:
        logger.exception("Verification resend failed for %s", user["email"])
        raise HTTPException(status_code=503, detail="تعذر إرسال رمز التحقق حالياً") from exc
    return {"success": True, "message": "تم إرسال رمز تحقق جديد"}


# ── POST /auth/login ──────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse, summary="تسجيل الدخول")
async def login(body: LoginRequest, request: Request) -> TokenResponse:
    identifier = (body.username or body.email or "").strip()
    user = _USERS.get(identifier)
    if user is None:
        user = _find_user_by_email(identifier)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="اسم المستخدم أو كلمة المرور غير صحيحة")
    if not user.get("active") or (user.get("password_hash") != "__admin_placeholder__" and not user.get("email_verified")):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="تحقق من بريدك الإلكتروني أولاً")

    if not _verify_password(body.password, user["password_hash"]):
        logger.warning("Failed login attempt for user: %s", body.username)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة",
        )

    jwt = _get_jwt_auth()
    access_token = jwt.issue_token(
        user_id=user["user_id"],
        tenant_id=user["tenant_id"],
        roles=user["roles"],
        token_type="access",
    )
    refresh_token = jwt.issue_token(
        user_id=user["user_id"],
        tenant_id=user["tenant_id"],
        roles=user["roles"],
        token_type="refresh",
    )

    logger.info("User logged in: %s", body.username)
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=3600,
        user_id=user["user_id"],
        roles=user["roles"],
        tenant_id=user["tenant_id"],
        user={"id": user["user_id"], "name": user.get("name", user["username"]), "email": user["email"], "username": user["username"]},
    )


@router.post("/google", response_model=TokenResponse, summary="تسجيل الدخول عبر Google")
async def google_login(body: SocialLoginRequest) -> TokenResponse:
    try:
        identity = await verify_google_id_token(body.token)
        user = _upsert_social_user(identity, body.tenant_id)
        logger.info("Google social login succeeded for user_id=%s", user["user_id"])
        return _issue_token_response(user)
    except SocialAuthError as exc:
        logger.warning("Google social login rejected: %s", str(exc))
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="تعذر التحقق من حساب Google") from exc


@router.post("/facebook", response_model=TokenResponse, summary="تسجيل الدخول عبر Facebook")
async def facebook_login(body: SocialLoginRequest) -> TokenResponse:
    try:
        identity = await verify_facebook_access_token(body.token)
        user = _upsert_social_user(identity, body.tenant_id)
        logger.info("Facebook social login succeeded for user_id=%s", user["user_id"])
        return _issue_token_response(user)
    except SocialAuthError as exc:
        logger.warning("Facebook social login rejected: %s", str(exc))
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="تعذر التحقق من حساب Facebook") from exc


# ── POST /auth/refresh ────────────────────────────────────────────────────────

@router.post("/refresh", response_model=TokenResponse, summary="تجديد التوكن")
async def refresh_token(body: RefreshRequest) -> TokenResponse:
    try:
        jwt = _get_jwt_auth()
        new_access = jwt.refresh_access_token(body.refresh_token)
        claims = jwt.validate_token(new_access)
        new_refresh = jwt.issue_token(
            claims.sub, claims.tenant_id, claims.roles, "refresh"
        )
        return TokenResponse(
            access_token=new_access,
            refresh_token=new_refresh,
            expires_in=3600,
            user_id=claims.sub,
            roles=claims.roles,
                tenant_id=claims.tenant_id,
            user={"id": claims.sub, "name": claims.sub, "email": "", "username": claims.sub},
        )
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))


# ── POST /auth/revoke ─────────────────────────────────────────────────────────

@router.post("/revoke", summary="إلغاء صلاحية التوكن")
async def revoke_token(body: RevokeRequest) -> Dict[str, Any]:
    jwt_auth = _get_jwt_auth()
    jwt_auth.revoke_token(body.token)
    return {"success": True, "message": "تم إلغاء صلاحية التوكن"}


@router.get("/apikeys", summary="قائمة مفاتيح API للمستخدم الحالي")
async def list_api_keys(request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    api_key_manager = get_api_key_manager()
    keys = api_key_manager.get_all_keys_for_user(user_id)
    return {"api_keys": [key.to_dict() for key in keys], "total": len(keys)}


@router.get("/apikeys/{key_id}", summary="الحصول على تفاصيل مفتاح API")
async def get_api_key_details(key_id: str, request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    api_key_manager = get_api_key_manager()
    api_key = api_key_manager.get_key_by_id(key_id)
    if not api_key or api_key.user_id != user_id:
        raise HTTPException(status_code=404, detail="مفتاح API غير موجود أو لا تملك صلاحية الوصول إليه")
    return api_key.to_dict()


@router.delete("/apikeys/{key_id}", summary="إلغاء مفتاح API")
async def revoke_api_key(key_id: str, request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    api_key_manager = get_api_key_manager()
    api_key = api_key_manager.get_key_by_id(key_id)
    if not api_key or api_key.user_id != user_id:
        raise HTTPException(status_code=404, detail="مفتاح API غير موجود أو لا تملك صلاحية الوصول إليه")
    if not api_key_manager.revoke_key(key_id):
        raise HTTPException(status_code=500, detail="فشل إلغاء مفتاح API")
    return {"success": True, "message": "تم إلغاء مفتاح API بنجاح"}


# ── GET /auth/me ──────────────────────────────────────────────────────────────

@router.get("/me", summary="معلومات المستخدم الحالي")
async def get_current_user(request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    roles = getattr(request.state, "roles", [])
    tenant_id = getattr(request.state, "tenant_id", "default")
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    return {
        "user_id": user_id,
        "roles": roles,
        "tenant_id": tenant_id,
        "permissions": [p.value for p in __import__(
            "security.rbac.rbac", fromlist=["get_all_permissions"]
        ).get_all_permissions(roles)],
    }


# ── POST /auth/apikeys ────────────────────────────────────────────────────────

@router.post("/apikeys", summary="إنشاء API Key جديد")
async def create_api_key(body: CreateAPIKeyRequest, request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", "anonymous")
    tenant_id = getattr(request.state, "tenant_id", "default")

    api_key_manager = get_api_key_manager()
    raw_key, api_key_obj = api_key_manager.generate_key(
        user_id=user_id,
        tenant_id=tenant_id,
        roles=body.roles,
        expires_in_seconds=body.expires_in_days * 86400 if body.expires_in_days else None,
        metadata={"name": body.name}
    )
    key_id = api_key_obj.key_id

    logger.info("API key created: %s for user %s", key_id, user_id)
    return {
        "key_id": key_id,
        "key": raw_key,
        "name": body.name,
        "roles": api_key_obj.roles,
        "user_id": user_id,
        "tenant_id": tenant_id,
        "expires_at": api_key_obj.expires_at,
        "warning": "احفظ هذا المفتاح بأمان — لن يُعرض مرة أخرى",
        "message": "تم إنشاء مفتاح API بنجاح. يرجى حفظه الآن."
    }


# ── GET /auth/users ───────────────────────────────────────────────────────────

@router.get("/users", summary="قائمة المستخدمين (admin فقط)")
async def list_users(request: Request) -> Dict[str, Any]:
    roles = getattr(request.state, "roles", [])
    if "admin" not in roles and "superadmin" not in roles:
        raise HTTPException(status_code=403, detail="يجب أن تكون admin")
    safe_users = [
        {k: v for k, v in u.items() if k not in ("password_hash",)}
        for u in _USERS.values()
    ]
    return {"users": safe_users, "total": len(safe_users)}
