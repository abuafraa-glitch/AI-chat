from __future__ import annotations

import logging
import os
import smtplib
import time
from contextlib import contextmanager
from email.message import EmailMessage
from typing import Any, Dict, List, Optional

import jwt
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from api.v1.auth.models import AuthCode, AuthIdentity, AuthUser
from api.v1.auth.social import SocialAuthError, verify_facebook_access_token, verify_google_id_token
from api.v1.auth.store import ACCESS_TTL, REFRESH_TTL, CODE_TTL, MAX_CODE_ATTEMPTS, active_session, allow_attempt, as_user_dict, create_session, get_user, get_user_by_email, hash_code, hash_password, issue_code, normalize_email, revoke_session, revoke_user_sessions, unique_username, verify_code, verify_password
from security.auth.api_key_manager import get_api_key_manager
from shared.database import Base, SessionLocal, engine

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["Authentication"])
_schema_ready = False


class RegisterRequest(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: str = Field(..., min_length=5, max_length=320)
    password: str = Field(..., min_length=8, max_length=200)
    tenant_id: str = Field(default="default", max_length=120)
    roles: List[str] = Field(default_factory=lambda: ["user"])


class LoginRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: str = Field(..., min_length=1, max_length=200)
    tenant_id: str = "default"


class SocialLoginRequest(BaseModel):
    token: str = Field(..., min_length=20, max_length=8192)
    tenant_id: str = "default"


class RefreshRequest(BaseModel):
    refresh_token: str = Field(..., min_length=20)


class VerifyEmailRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=320)
    code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class ResendVerificationRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=320)


class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=320)


class ResetPasswordRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=320)
    code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")
    new_password: str = Field(..., min_length=8, max_length=200)


class RevokeRequest(BaseModel):
    token: str = Field(..., min_length=20)


class CreateAPIKeyRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    roles: List[str] = Field(default_factory=lambda: ["user"])
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


def _ensure_schema() -> None:
    global _schema_ready
    if not _schema_ready:
        Base.metadata.create_all(bind=engine)
        _schema_ready = True


@contextmanager
def db_context() -> Any:
    _ensure_schema()
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    return forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "unknown")


def _smtp_configured() -> bool:
    return all(os.getenv(key) for key in ("SMTP_HOST", "SMTP_PORT", "SMTP_USERNAME", "SMTP_PASSWORD", "SMTP_FROM_EMAIL"))


def _send_code_email(email: str, code: str, purpose: str) -> None:
    recipient = normalize_email(email)
    if "@" not in recipient or not _smtp_configured():
        raise RuntimeError("SMTP configuration is incomplete")
    subject = "رمز التحقق من البريد الإلكتروني - Hajeen AI" if purpose == "email_verification" else "رمز إعادة تعيين كلمة المرور - Hajeen AI"
    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = os.environ["SMTP_FROM_EMAIL"]
    message["To"] = recipient
    message.set_content(f"مرحباً في Hajeen AI،\n\nرمزك هو: {code}\nيظل صالحاً لمدة {CODE_TTL // 60} دقائق. إذا لم تطلب هذه العملية فتجاهل الرسالة.")
    host = os.environ["SMTP_HOST"]
    port = int(os.environ.get("SMTP_PORT", "587"))
    use_tls = os.getenv("SMTP_USE_TLS", "true").lower() not in {"0", "false", "no"}
    with smtplib.SMTP(host, port, timeout=15) as smtp:
        smtp.ehlo()
        if use_tls:
            smtp.starttls()
            smtp.ehlo()
        smtp.login(os.environ["SMTP_USERNAME"], os.environ["SMTP_PASSWORD"])
        smtp.send_message(message, from_addr=os.environ["SMTP_FROM_EMAIL"], to_addrs=[recipient])


def _new_code_and_send(db: Session, user: AuthUser, purpose: str) -> None:
    previous = db.scalar(select(AuthCode).where(AuthCode.user_id == user.user_id, AuthCode.purpose == purpose, AuthCode.consumed_at.is_(None)).order_by(AuthCode.created_at.desc()))
    if previous and previous.last_sent_at and (time.time() - previous.last_sent_at.timestamp()) < 60:
        raise HTTPException(status_code=429, detail="انتظر دقيقة قبل طلب رمز جديد")
    code = issue_code(db, user, purpose)
    _send_code_email(user.email, code, purpose)


def _jwt() -> Any:
    from security.auth.jwt_auth import JWTAuthenticator
    return JWTAuthenticator(secret=os.getenv("JWT_SECRET", ""))


def _token_jti(token: str) -> str:
    try:
        claims = jwt.decode(token, options={"verify_signature": False, "verify_exp": False})
        return str(claims["jti"])
    except Exception as exc:
        raise HTTPException(status_code=401, detail="جلسة غير صالحة") from exc


def _issue_tokens(db: Session, user: AuthUser, request: Request) -> TokenResponse:
    auth = _jwt()
    access = auth.issue_token(user.user_id, user.tenant_id, list(user.roles or ["user"]), "access")
    refresh = auth.issue_token(user.user_id, user.tenant_id, list(user.roles or ["user"]), "refresh")
    create_session(db, user, _token_jti(refresh), request.headers.get("user-agent"), _client_ip(request))
    return TokenResponse(access_token=access, refresh_token=refresh, expires_in=ACCESS_TTL, user_id=user.user_id, roles=list(user.roles or ["user"]), tenant_id=user.tenant_id, user=as_user_dict(user))


def _generic_auth_error() -> HTTPException:
    return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="بيانات الدخول غير صحيحة")


def _find_by_username(db: Session, username: str) -> AuthUser | None:
    return db.scalar(select(AuthUser).where(AuthUser.username == username))


@router.post("/register", status_code=201, summary="تسجيل مستخدم جديد")
async def register(body: RegisterRequest) -> Dict[str, Any]:
    with db_context() as db:
        email = normalize_email(body.email)
        if get_user_by_email(db, email):
            raise HTTPException(status_code=400, detail="تعذر إنشاء الحساب بهذه البيانات")
        username = (body.username or unique_username(db, email)).strip()
        if _find_by_username(db, username):
            raise HTTPException(status_code=400, detail="تعذر إنشاء الحساب بهذه البيانات")
        user = AuthUser(username=username, name=body.name or username, email=email, password_hash=hash_password(body.password), roles=body.roles or ["user"], tenant_id=body.tenant_id, active=False, email_verified=False)
        db.add(user)
        db.flush()
        try:
            _new_code_and_send(db, user, "email_verification")
        except HTTPException:
            raise
        except Exception as exc:
            logger.exception("Verification email delivery failed for %s", email)
            raise HTTPException(status_code=503, detail="تعذر إرسال رمز التحقق حالياً") from exc
        return {"success": True, "pending_verification": True, "user_id": user.user_id, "username": user.username, "email": user.email, "message": "تم إنشاء الحساب. تحقق من بريدك الإلكتروني لإكمال التسجيل."}


@router.post("/verify-email", summary="تأكيد البريد الإلكتروني")
async def verify_email(body: VerifyEmailRequest) -> Dict[str, Any]:
    with db_context() as db:
        user = get_user_by_email(db, body.email)
        if not user or user.email_verified:
            raise HTTPException(status_code=400, detail="رمز التحقق غير صالح")
        ok, reason = verify_code(db, user, "email_verification", body.code)
        if not ok:
            detail = "تم تجاوز عدد المحاولات" if reason == "too_many" else "انتهت صلاحية رمز التحقق" if reason == "expired" else "رمز التحقق غير صحيح"
            raise HTTPException(status_code=429 if reason == "too_many" else 400, detail=detail)
        user.email_verified = True
        user.active = True
        return {"success": True, "email_verified": True, "message": "تم تأكيد البريد الإلكتروني بنجاح"}


@router.post("/resend-verification", summary="إعادة إرسال رمز التحقق")
async def resend_verification(body: ResendVerificationRequest) -> Dict[str, Any]:
    with db_context() as db:
        user = get_user_by_email(db, body.email)
        if not user or user.email_verified:
            return {"success": True, "message": "إذا كان الحساب بحاجة إلى تحقق فسيتم إرسال رمز جديد"}
        try:
            _new_code_and_send(db, user, "email_verification")
        except HTTPException:
            raise
        except Exception as exc:
            logger.exception("Verification resend failed")
            raise HTTPException(status_code=503, detail="تعذر إرسال رمز التحقق حالياً") from exc
        return {"success": True, "message": "تم إرسال رمز تحقق جديد"}


@router.post("/login", response_model=TokenResponse, summary="تسجيل الدخول")
async def login(body: LoginRequest, request: Request) -> TokenResponse:
    identifier = (body.username or body.email or "").strip()
    with db_context() as db:
        if not allow_attempt(db, f"login:{_client_ip(request)}:{normalize_email(identifier)}", 10, 900):
            raise HTTPException(status_code=429, detail="محاولات كثيرة. حاول لاحقاً")
        user = _find_by_username(db, identifier) or get_user_by_email(db, identifier)
        if not user or not user.active or not user.email_verified or not verify_password(body.password, user.password_hash):
            raise _generic_auth_error()
        if db.scalar(select(AuthIdentity).where(AuthIdentity.user_id == user.user_id, AuthIdentity.provider.in_(["google", "facebook"]))) and not user.password_hash:
            raise _generic_auth_error()
        return _issue_tokens(db, user, request)



def _upsert_social(db: Session, identity: Dict[str, Any], tenant_id: str) -> AuthUser:
    provider = identity["provider"]
    subject = identity["provider_sub"]
    row = db.scalar(select(AuthIdentity).where(AuthIdentity.provider == provider, AuthIdentity.provider_sub == subject))
    user = get_user(db, row.user_id) if row else None
    email = normalize_email(identity["email"])
    if user is None:
        user = get_user_by_email(db, email)
        if user is None:
            user = AuthUser(username=unique_username(db, email), name=identity["name"], email=email, roles=["user"], tenant_id=tenant_id, active=True, email_verified=bool(identity.get("email_verified")))
            db.add(user)
            db.flush()
        elif not user.active:
            raise SocialAuthError("الحساب غير نشط")
        if not identity.get("email_verified"):
            raise SocialAuthError("البريد الاجتماعي غير موثق")
        if row is None:
            row = AuthIdentity(user_id=user.user_id, provider=provider, provider_sub=subject, email=email)
            db.add(row)
    else:
        if row.email and row.email != email:
            raise SocialAuthError("هوية المزود غير متطابقة")
    user.active = True
    user.email_verified = True
    if not user.name:
        user.name = identity["name"]
    if row:
        row.last_login_at = __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
    return user


@router.post("/google", response_model=TokenResponse, summary="تسجيل الدخول عبر Google")
async def google_login(body: SocialLoginRequest, request: Request) -> TokenResponse:
    try:
        identity = await verify_google_id_token(body.token)
        with db_context() as db:
            return _issue_tokens(db, _upsert_social(db, identity, body.tenant_id), request)
    except SocialAuthError as exc:
        raise HTTPException(status_code=401, detail="تعذر التحقق من حساب Google") from exc


@router.post("/facebook", response_model=TokenResponse, summary="تسجيل الدخول عبر Facebook")
async def facebook_login(body: SocialLoginRequest, request: Request) -> TokenResponse:
    try:
        identity = await verify_facebook_access_token(body.token)
        with db_context() as db:
            return _issue_tokens(db, _upsert_social(db, identity, body.tenant_id), request)
    except SocialAuthError as exc:
        raise HTTPException(status_code=401, detail="تعذر التحقق من حساب Facebook") from exc


@router.post("/refresh", response_model=TokenResponse, summary="تجديد التوكن")
async def refresh_token(body: RefreshRequest, request: Request) -> TokenResponse:
    with db_context() as db:
        try:
            auth = _jwt()
            claims = auth.validate_token(body.refresh_token)
            if claims.type != "refresh" or active_session(db, claims.jti) is None:
                raise PermissionError("جلسة منتهية أو ملغاة")
            user = get_user(db, claims.sub)
            if not user or not user.active:
                raise PermissionError("الحساب غير نشط")
            revoke_session(db, claims.jti)
            return _issue_tokens(db, user, request)
        except PermissionError as exc:
            raise HTTPException(status_code=401, detail="جلسة منتهية أو غير صالحة") from exc


@router.post("/logout", summary="تسجيل الخروج وإلغاء الجلسة")
async def logout(body: RevokeRequest) -> Dict[str, Any]:
    with db_context() as db:
        jti = _token_jti(body.token)
        revoke_session(db, jti)
        try:
            _jwt().revoke_token(body.token)
        except Exception:
            pass
    return {"success": True, "message": "تم تسجيل الخروج"}


@router.post("/revoke", summary="إلغاء صلاحية التوكن")
async def revoke_token(body: RevokeRequest) -> Dict[str, Any]:
    return await logout(body)


@router.post("/forgot-password", summary="طلب إعادة تعيين كلمة المرور")
async def forgot_password(body: ForgotPasswordRequest, request: Request) -> Dict[str, Any]:
    generic = {"success": True, "message": "إذا كان البريد مسجلاً فستصل إليه تعليمات إعادة التعيين"}
    with db_context() as db:
        if not allow_attempt(db, f"forgot:{_client_ip(request)}:{normalize_email(body.email)}", 3, 900):
            return generic
        user = get_user_by_email(db, body.email)
        if not user or not user.password_hash:
            return generic
        try:
            _new_code_and_send(db, user, "password_reset")
        except Exception:
            logger.exception("Password reset delivery failed")
        return generic


@router.post("/reset-password", summary="تعيين كلمة مرور جديدة")
async def reset_password(body: ResetPasswordRequest) -> Dict[str, Any]:
    with db_context() as db:
        user = get_user_by_email(db, body.email)
        if not user:
            raise HTTPException(status_code=400, detail="رمز إعادة التعيين غير صالح")
        ok, reason = verify_code(db, user, "password_reset", body.code)
        if not ok:
            raise HTTPException(status_code=429 if reason == "too_many" else 400, detail="رمز إعادة التعيين غير صالح أو منتهي")
        user.password_hash = hash_password(body.new_password)
        user.active = bool(user.email_verified)
        revoke_user_sessions(db, user.user_id)
        return {"success": True, "message": "تم تغيير كلمة المرور بنجاح"}


@router.get("/me", summary="معلومات المستخدم الحالي")
async def get_current_user(request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    with db_context() as db:
        user = get_user(db, user_id)
        if not user:
            raise HTTPException(status_code=401, detail="غير مصادق")
        roles = list(user.roles or [])
        permissions = [p.value for p in __import__("security.rbac.rbac", fromlist=["get_all_permissions"]).get_all_permissions(roles)]
        return {"user_id": user.user_id, "roles": roles, "tenant_id": user.tenant_id, "permissions": permissions, "user": as_user_dict(user)}


@router.get("/apikeys", summary="قائمة مفاتيح API للمستخدم الحالي")
async def list_api_keys(request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    keys = get_api_key_manager().get_all_keys_for_user(user_id)
    return {"api_keys": [key.to_dict() for key in keys], "total": len(keys)}


@router.get("/apikeys/{key_id}", summary="الحصول على تفاصيل مفتاح API")
async def get_api_key_details(key_id: str, request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    key = get_api_key_manager().get_key_by_id(key_id)
    if not user_id or not key or key.user_id != user_id:
        raise HTTPException(status_code=404, detail="مفتاح API غير موجود")
    return key.to_dict()


@router.delete("/apikeys/{key_id}", summary="إلغاء مفتاح API")
async def revoke_api_key(key_id: str, request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    key = get_api_key_manager().get_key_by_id(key_id)
    if not user_id or not key or key.user_id != user_id:
        raise HTTPException(status_code=404, detail="مفتاح API غير موجود")
    if not get_api_key_manager().revoke_key(key_id):
        raise HTTPException(status_code=500, detail="فشل إلغاء مفتاح API")
    return {"success": True, "message": "تم إلغاء مفتاح API بنجاح"}


@router.post("/apikeys", summary="إنشاء API Key جديد")
async def create_api_key(body: CreateAPIKeyRequest, request: Request) -> Dict[str, Any]:
    user_id = getattr(request.state, "user_id", None)
    tenant_id = getattr(request.state, "tenant_id", "default")
    if not user_id:
        raise HTTPException(status_code=401, detail="غير مصادق")
    raw_key, key = get_api_key_manager().generate_key(user_id=user_id, tenant_id=tenant_id, roles=body.roles, expires_in_seconds=body.expires_in_days * 86400 if body.expires_in_days else None, metadata={"name": body.name})
    return {"key_id": key.key_id, "key": raw_key, "name": body.name, "roles": key.roles, "user_id": user_id, "tenant_id": tenant_id, "expires_at": key.expires_at, "warning": "احفظ هذا المفتاح بأمان — لن يُعرض مرة أخرى", "message": "تم إنشاء مفتاح API بنجاح."}


@router.get("/users", summary="قائمة المستخدمين (admin فقط)")
async def list_users(request: Request) -> Dict[str, Any]:
    roles = getattr(request.state, "roles", [])
    if "admin" not in roles and "superadmin" not in roles:
        raise HTTPException(status_code=403, detail="يجب أن تكون admin")
    with db_context() as db:
        users = db.scalars(select(AuthUser)).all()
        safe = [{**as_user_dict(user), "user_id": user.user_id, "roles": list(user.roles or []), "tenant_id": user.tenant_id} for user in users]
        return {"users": safe, "total": len(safe)}
