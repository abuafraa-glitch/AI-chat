"""Regression tests for mandatory email ownership verification."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
import os
import importlib

os.environ.setdefault("JWT_SECRET", "otp-test-secret-012345678901234567890")
os.environ["ENABLE_AUTH"] = "true"

from fastapi.testclient import TestClient
from sqlalchemy import delete, select

from api.main import app
from api.v1.auth.models import AuthCode, AuthIdentity, AuthSession, AuthThrottle, AuthUser
from api.v1.auth.router import db_context

auth_router = importlib.import_module("api.v1.auth.router")
client = TestClient(app, raise_server_exceptions=False)


def clean() -> None:
    with db_context() as db:
        for model in (AuthThrottle, AuthCode, AuthSession, AuthIdentity, AuthUser):
            db.execute(delete(model))


def test_registration_is_pending_until_otp(monkeypatch) -> None:
    clean()
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_code_email", lambda email, code, purpose: sent.append((email, code)))
    email = "otp-user@example.com"
    registration = client.post("/api/v1/auth/register", json={"name": "OTP User", "email": email, "password": "secret123"})
    assert registration.status_code == 201
    assert registration.json()["pending_verification"] is True
    assert "access_token" not in registration.json()
    assert sent and sent[0][0] == email
    assert client.post("/api/v1/auth/login", json={"email": email, "password": "secret123"}).status_code in (401, 403)
    verification = client.post("/api/v1/auth/verify-email", json={"email": email, "code": sent[0][1]})
    assert verification.status_code == 200 and verification.json()["email_verified"] is True
    assert client.post("/api/v1/auth/login", json={"email": email, "password": "secret123"}).status_code == 200


def test_resend_verification_is_public_and_throttled(monkeypatch) -> None:
    clean()
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_code_email", lambda email, code, purpose: sent.append((email, code)))
    client.post("/api/v1/auth/register", json={"name": "Resend User", "email": "otp-resend@example.com", "password": "secret123"})
    with db_context() as db:
        code = db.scalar(select(AuthCode).order_by(AuthCode.created_at.desc()))
        if code:
            code.last_sent_at = datetime.now(timezone.utc) - timedelta(seconds=61)
    response = client.post("/api/v1/auth/resend-verification", json={"email": "otp-resend@example.com"})
    assert response.status_code == 200 and sent
    throttled = client.post("/api/v1/auth/resend-verification", json={"email": "otp-resend@example.com"})
    assert throttled.status_code == 429


def test_registration_normalizes_recipient_and_never_uses_admin_email(monkeypatch) -> None:
    clean()
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_code_email", lambda email, code, purpose: sent.append((email, code)))
    response = client.post("/api/v1/auth/register", json={"name": "Recipient User", "email": "  recipient@example.com ", "password": "secret123"})
    assert response.status_code == 201
    assert sent and sent[0][0] == "recipient@example.com"
    assert sent[0][0] != os.getenv("SMTP_FROM_EMAIL", "")


def test_resend_unknown_email_does_not_send_otp(monkeypatch) -> None:
    clean()
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_code_email", lambda email, code, purpose: sent.append((email, code)))
    response = client.post("/api/v1/auth/resend-verification", json={"email": "does-not-exist@example.com"})
    assert response.status_code == 200 and sent == []


def test_email_login_rejects_social_only_account_without_password() -> None:
    clean()
    response = client.post("/api/v1/auth/login", json={"email": "social-only@example.com", "password": "secret123"})
    assert response.status_code in (401, 403)
