"""Phase 5 API boundary proofs.

These tests exercise the real FastAPI application with its auth middleware and
routers. They intentionally do not claim tenant-resource E2E proof because the
current application does not expose a persisted resource fixture suitable for
that claim.
"""
from __future__ import annotations

import os

os.environ.setdefault("JWT_SECRET", "phase5-test-secret-only-not-production")
os.environ["ENABLE_AUTH"] = "true"

from fastapi.testclient import TestClient

from api.main import app


client = TestClient(app, raise_server_exceptions=False)


def test_unauthenticated_protected_request_is_denied() -> None:
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401
    assert response.json()["message"] in {"يجب تقديم Authorization header أو X-API-Key", "غير مصادق"}


def test_invalid_token_is_denied() -> None:
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer definitely-invalid-token"},
    )
    assert response.status_code == 401


def test_authenticated_login_and_principal_context() -> None:
    login = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "HajeenAdmin2024!"},
    )
    assert login.status_code == 200
    payload = login.json()
    assert payload["access_token"]
    assert payload["tenant_id"] == "default"
    assert "superadmin" in payload["roles"]

    me = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {payload['access_token']}"},
    )
    assert me.status_code == 200
    principal = me.json()
    assert principal["user_id"] == payload["user_id"]
    assert principal["tenant_id"] == payload["tenant_id"]


def test_malformed_login_request_is_rejected() -> None:
    response = client.post("/api/v1/auth/login", json={"username": "admin"})
    assert response.status_code == 422
