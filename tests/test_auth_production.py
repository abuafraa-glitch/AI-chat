from __future__ import annotations

from types import SimpleNamespace

import pytest
from sqlalchemy import delete

import importlib

auth_router_module = importlib.import_module("api.v1.auth.router")
from api.v1.auth.models import AuthCode, AuthIdentity, AuthSession, AuthThrottle, AuthUser
from api.v1.auth.router import LoginRequest, RefreshRequest, RegisterRequest, ResetPasswordRequest, VerifyEmailRequest, _ensure_schema, db_context, login, logout, refresh_token, register, reset_password, verify_email
from shared.database import Base, engine


@pytest.fixture(autouse=True)
def clean_database():
    _ensure_schema()
    with db_context() as db:
        for model in (AuthThrottle, AuthCode, AuthSession, AuthIdentity, AuthUser):
            db.execute(delete(model))
    yield


def request() -> SimpleNamespace:
    return SimpleNamespace(headers={"user-agent": "pytest"}, client=SimpleNamespace(host="127.0.0.1"))


@pytest.mark.asyncio
async def test_email_signup_requires_user_verification_and_persists(monkeypatch):
    delivered = {}
    monkeypatch.setattr(auth_router_module, "_send_code_email", lambda email, code, purpose: delivered.update(email=email, code=code, purpose=purpose))
    response = await register(RegisterRequest(email="User@Example.com", password="correct horse battery", name="User"))
    assert response["pending_verification"] is True
    assert delivered["email"] == "user@example.com"
    assert delivered["purpose"] == "email_verification"
    verified = await verify_email(VerifyEmailRequest(email="user@example.com", code=delivered["code"]))
    assert verified["email_verified"] is True
    with db_context() as db:
        user = db.scalar(__import__("sqlalchemy").select(AuthUser).where(AuthUser.email == "user@example.com"))
        assert user is not None and user.active and user.password_hash.startswith("$2")


@pytest.mark.asyncio
async def test_login_refresh_rotation_and_logout(monkeypatch):
    delivered = {}
    monkeypatch.setattr(auth_router_module, "_send_code_email", lambda email, code, purpose: delivered.update(code=code))
    await register(RegisterRequest(email="login@example.com", password="strong-password"))
    await verify_email(VerifyEmailRequest(email="login@example.com", code=delivered["code"]))
    first = await login(LoginRequest(email="login@example.com", password="strong-password"), request())
    second = await refresh_token(RefreshRequest(refresh_token=first.refresh_token), request())
    assert second.user_id == first.user_id
    with pytest.raises(Exception):
        await refresh_token(RefreshRequest(refresh_token=first.refresh_token), request())
    await logout(__import__("api.v1.auth.router", fromlist=["RevokeRequest"]).RevokeRequest(token=second.refresh_token))
    with pytest.raises(Exception):
        await refresh_token(RefreshRequest(refresh_token=second.refresh_token), request())


@pytest.mark.asyncio
async def test_reset_password_revokes_existing_sessions(monkeypatch):
    delivered = {}
    monkeypatch.setattr(auth_router_module, "_send_code_email", lambda email, code, purpose: delivered.update(code=code, purpose=purpose))
    await register(RegisterRequest(email="reset@example.com", password="old-password"))
    await verify_email(VerifyEmailRequest(email="reset@example.com", code=delivered["code"]))
    first = await login(LoginRequest(email="reset@example.com", password="old-password"), request())
    delivered.clear()
    await auth_router_module.forgot_password(__import__("api.v1.auth.router", fromlist=["ForgotPasswordRequest"]).ForgotPasswordRequest(email="reset@example.com"), request())
    await reset_password(ResetPasswordRequest(email="reset@example.com", code=delivered["code"], new_password="new-password"))
    with pytest.raises(Exception):
        await refresh_token(RefreshRequest(refresh_token=first.refresh_token), request())
    with pytest.raises(Exception):
        await login(LoginRequest(email="reset@example.com", password="old-password"), request())
    new_login = await login(LoginRequest(email="reset@example.com", password="new-password"), request())
    assert new_login.user_id == first.user_id


@pytest.mark.asyncio
async def test_social_identity_links_to_existing_email(monkeypatch):
    delivered = {}
    monkeypatch.setattr(auth_router_module, "_send_code_email", lambda email, code, purpose: delivered.update(code=code))
    await register(RegisterRequest(email="social@example.com", password="password-one"))
    await verify_email(VerifyEmailRequest(email="social@example.com", code=delivered["code"]))
    monkeypatch.setattr(auth_router_module, "verify_google_id_token", lambda token: pytest.fail("not called"))
    with db_context() as db:
        user = db.scalar(__import__("sqlalchemy").select(AuthUser).where(AuthUser.email == "social@example.com"))
        assert user is not None
        identity = AuthIdentity(user_id=user.user_id, provider="google", provider_sub="google-sub-1", email=user.email)
        db.add(identity)
    with db_context() as db:
        users = db.scalars(__import__("sqlalchemy").select(AuthUser).where(AuthUser.email == "social@example.com")).all()
        identities = db.scalars(__import__("sqlalchemy").select(AuthIdentity).where(AuthIdentity.provider_sub == "google-sub-1")).all()
        assert len(users) == 1 and len(identities) == 1 and identities[0].user_id == users[0].user_id
