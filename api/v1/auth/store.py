from __future__ import annotations

import hashlib
import hmac
import os
import secrets
import time
from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from sqlalchemy import select
from sqlalchemy.orm import Session

from .models import AuthCode, AuthIdentity, AuthSession, AuthThrottle, AuthUser, utcnow

ACCESS_TTL = int(os.getenv("ACCESS_TOKEN_TTL", "3600"))
REFRESH_TTL = int(os.getenv("REFRESH_TOKEN_TTL", str(86400 * 30)))
CODE_TTL = int(os.getenv("AUTH_CODE_TTL", "600"))
MAX_CODE_ATTEMPTS = int(os.getenv("AUTH_CODE_MAX_ATTEMPTS", "5"))


def normalize_email(value: str) -> str:
    return value.strip().lower()


def aware(value: datetime) -> datetime:
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value


def hash_password(password: str) -> str:
    if len(password) < 8:
        raise ValueError("Password must contain at least 8 characters")
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=int(os.getenv("BCRYPT_ROUNDS", "12")))).decode("ascii")


def verify_password(password: str, stored_hash: str | None) -> bool:
    if not stored_hash or not stored_hash.startswith("$2"):
        return False
    try:
        return bcrypt.checkpw(password.encode("utf-8"), stored_hash.encode("ascii"))
    except (ValueError, TypeError):
        return False


def hash_code(code: str) -> str:
    secret = os.getenv("VERIFICATION_CODE_SALT", os.getenv("JWT_SECRET", "change-me"))
    return hmac.new(secret.encode(), code.encode(), hashlib.sha256).hexdigest()


def new_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def as_user_dict(user: AuthUser) -> dict[str, Any]:
    return {
        "id": user.user_id,
        "name": user.name,
        "email": user.email,
        "username": user.username,
        "email_verified": user.email_verified,
        "active": user.active,
    }


def get_user_by_email(db: Session, email: str) -> AuthUser | None:
    return db.scalar(select(AuthUser).where(AuthUser.email == normalize_email(email)))


def get_user(db: Session, user_id: str) -> AuthUser | None:
    return db.scalar(select(AuthUser).where(AuthUser.user_id == user_id))


def unique_username(db: Session, email: str) -> str:
    base = "".join(ch for ch in email.split("@", 1)[0] if ch.isalnum() or ch in "._-")[:60] or "user"
    candidate = base
    index = 1
    while db.scalar(select(AuthUser).where(AuthUser.username == candidate)) is not None:
        index += 1
        candidate = f"{base[:55]}_{index}"
    return candidate


def issue_code(db: Session, user: AuthUser, purpose: str) -> str:
    code = new_code()
    row = db.scalar(select(AuthCode).where(AuthCode.user_id == user.user_id, AuthCode.purpose == purpose, AuthCode.consumed_at.is_(None)))
    if row is None:
        row = AuthCode(user_id=user.user_id, purpose=purpose, code_hash=hash_code(code), expires_at=utcnow() + timedelta(seconds=CODE_TTL), attempts=0, last_sent_at=utcnow())
        db.add(row)
    else:
        row.code_hash = hash_code(code)
        row.expires_at = utcnow() + timedelta(seconds=CODE_TTL)
        row.attempts = 0
        row.last_sent_at = utcnow()
    db.flush()
    return code


def verify_code(db: Session, user: AuthUser, purpose: str, code: str) -> tuple[bool, str]:
    row = db.scalar(select(AuthCode).where(AuthCode.user_id == user.user_id, AuthCode.purpose == purpose, AuthCode.consumed_at.is_(None)).order_by(AuthCode.created_at.desc()))
    if row is None:
        return False, "invalid"
    if row.attempts >= MAX_CODE_ATTEMPTS:
        return False, "too_many"
    row.attempts += 1
    if utcnow() > aware(row.expires_at):
        return False, "expired"
    if not hmac.compare_digest(row.code_hash, hash_code(code)):
        return False, "invalid"
    row.consumed_at = utcnow()
    return True, "ok"


def create_session(db: Session, user: AuthUser, jti: str, user_agent: str | None, ip_address: str | None) -> AuthSession:
    session = AuthSession(jti=jti, user_id=user.user_id, tenant_id=user.tenant_id, expires_at=datetime.now(timezone.utc) + timedelta(seconds=REFRESH_TTL), user_agent=user_agent, ip_address=ip_address)
    db.add(session)
    db.flush()
    return session


def active_session(db: Session, jti: str) -> AuthSession | None:
    row = db.scalar(select(AuthSession).where(AuthSession.jti == jti))
    if row is None or row.revoked_at is not None or aware(row.expires_at) <= utcnow():
        return None
    return row


def revoke_session(db: Session, jti: str) -> None:
    row = db.scalar(select(AuthSession).where(AuthSession.jti == jti))
    if row and row.revoked_at is None:
        row.revoked_at = utcnow()


def revoke_user_sessions(db: Session, user_id: str) -> None:
    rows = db.scalars(select(AuthSession).where(AuthSession.user_id == user_id, AuthSession.revoked_at.is_(None))).all()
    now = utcnow()
    for row in rows:
        row.revoked_at = now


def allow_attempt(db: Session, key: str, limit: int, window_seconds: int) -> bool:
    now = utcnow()
    row = db.scalar(select(AuthThrottle).where(AuthThrottle.throttle_key == key))
    if row is None:
        db.add(AuthThrottle(throttle_key=key, window_started_at=now, attempts=1))
        db.flush()
        return True
    if (now - aware(row.window_started_at)).total_seconds() >= window_seconds:
        row.window_started_at = now
        row.attempts = 1
        return True
    if row.attempts >= limit:
        return False
    row.attempts += 1
    return True
