"""Regression tests for mandatory email ownership verification."""
from __future__ import annotations

import os

os.environ.setdefault("JWT_SECRET", "otp-test-secret")
os.environ["ENABLE_AUTH"] = "true"
os.environ.setdefault("SMTP_HOST", "smtp.test")
os.environ.setdefault("SMTP_PORT", "587")
os.environ.setdefault("SMTP_USERNAME", "tester@example.com")
os.environ.setdefault("SMTP_PASSWORD", "test-password")
os.environ.setdefault("SMTP_FROM_EMAIL", "tester@example.com")

from fastapi.testclient import TestClient

from api.main import app
import importlib

from api.v1.auth import router as _router_object

auth_router = importlib.import_module("api.v1.auth.router")


client = TestClient(app, raise_server_exceptions=False)


def test_registration_is_pending_until_otp(monkeypatch) -> None:
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_verification_email", lambda email, code: sent.append((email, code)))
    email = "otp-user@example.com"
    auth_router._USERS.pop("otp-user", None)

    registration = client.post(
        "/api/v1/auth/register",
        json={"name": "OTP User", "email": email, "password": "secret123", "username": "otp-user"},
    )
    assert registration.status_code == 201
    assert registration.json()["pending_verification"] is True
    assert "access_token" not in registration.json()
    assert sent and sent[0][0] == email

    login = client.post("/api/v1/auth/login", json={"email": email, "password": "secret123"})
    assert login.status_code == 403

    verification = client.post(
        "/api/v1/auth/verify-email",
        json={"email": email, "code": sent[0][1]},
    )
    assert verification.status_code == 200
    assert verification.json()["email_verified"] is True

    login = client.post("/api/v1/auth/login", json={"email": email, "password": "secret123"})
    assert login.status_code == 200
    auth_router._USERS.pop("otp-user", None)


def test_resend_verification_is_public_and_throttled(monkeypatch) -> None:
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_verification_email", lambda email, code: sent.append((email, code)))
    email = "otp-resend@example.com"
    auth_router._USERS.pop("otp-resend", None)
    user = {
        "user_id": "usr_resend",
        "username": "otp-resend",
        "name": "Resend User",
        "email": email,
        "password_hash": auth_router._hash_password("secret123"),
        "roles": ["user"],
        "tenant_id": "default",
        "active": False,
        "email_verified": False,
        "verification_sent_at": 0,
    }
    auth_router._USERS["otp-resend"] = user

    response = client.post("/api/v1/auth/resend-verification", json={"email": email})
    assert response.status_code == 200
    assert sent
    throttled = client.post("/api/v1/auth/resend-verification", json={"email": email})
    assert throttled.status_code == 429
    auth_router._USERS.pop("otp-resend", None)


def test_registration_normalizes_recipient_and_never_uses_admin_email(monkeypatch) -> None:
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_verification_email", lambda email, code: sent.append((email, code)))
    username = "otp-recipient-user"
    email = "  recipient@example.com "
    auth_router._USERS.pop(username, None)

    response = client.post(
        "/api/v1/auth/register",
        json={"name": "Recipient User", "email": email, "password": "secret123", "username": username},
    )
    assert response.status_code == 201
    assert sent == [("recipient@example.com", sent[0][1])]
    assert sent[0][0] != os.environ["SMTP_FROM_EMAIL"]
    auth_router._USERS.pop(username, None)


def test_resend_unknown_email_does_not_send_otp(monkeypatch) -> None:
    sent: list[tuple[str, str]] = []
    monkeypatch.setattr(auth_router, "_send_verification_email", lambda email, code: sent.append((email, code)))
    response = client.post(
        "/api/v1/auth/resend-verification",
        json={"email": "does-not-exist@example.com"},
    )
    assert response.status_code == 200
    assert sent == []


def test_email_login_rejects_social_only_account_without_otp(monkeypatch) -> None:
    username = "social-only-email"
    email = "social-only@example.com"
    auth_router._USERS[username] = {
        "user_id": "usr_social_only",
        "username": username,
        "name": "Social Only",
        "email": email,
        "password_hash": "__social_only__",
        "roles": ["user"],
        "tenant_id": "default",
        "active": True,
        "email_verified": True,
        "social_identities": {"google": "google-subject"},
    }

    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "secret123"},
    )

    assert response.status_code == 401
    assert "Google" in response.json()["message"]
    auth_router._USERS.pop(username, None)
