import os

import pytest
import respx
from httpx import Response

from api.v1.auth.social import (
    SocialAuthError,
    verify_facebook_access_token,
    verify_google_id_token,
)


@pytest.mark.asyncio
@respx.mock
async def test_google_id_token_requires_configured_audience(monkeypatch):
    monkeypatch.setenv("GOOGLE_WEB_CLIENT_ID", "web-client-id")
    route = respx.get("https://oauth2.googleapis.com/tokeninfo").mock(
        return_value=Response(
            200,
            json={
                "aud": "unexpected-client",
                "sub": "google-sub-1",
                "email": "user@example.com",
                "email_verified": "true",
                "name": "User",
            },
        )
    )
    with pytest.raises(SocialAuthError, match="audience"):
        await verify_google_id_token("g" * 32)
    assert route.called


@pytest.mark.asyncio
@respx.mock
async def test_facebook_token_must_belong_to_hajeen_app(monkeypatch):
    monkeypatch.setenv("FACEBOOK_APP_ID", "1539038397444455")
    monkeypatch.setenv("FACEBOOK_APP_SECRET", "server-secret")
    route = respx.get("https://graph.facebook.com/debug_token").mock(
        return_value=Response(
            200,
            json={"data": {"is_valid": True, "app_id": "another-app"}},
        )
    )
    with pytest.raises(SocialAuthError, match="app mismatch"):
        await verify_facebook_access_token("f" * 32)
    assert route.called


@pytest.mark.asyncio
@respx.mock
async def test_facebook_verification_fetches_profile_without_logging_token(monkeypatch):
    monkeypatch.setenv("FACEBOOK_APP_ID", "1539038397444455")
    monkeypatch.setenv("FACEBOOK_APP_SECRET", "server-secret")
    respx.get("https://graph.facebook.com/debug_token").mock(
        return_value=Response(
            200,
            json={"data": {"is_valid": True, "app_id": "1539038397444455"}},
        )
    )
    profile_route = respx.get("https://graph.facebook.com/me").mock(
        return_value=Response(
            200,
            json={"id": "facebook-sub-1", "name": "User", "email": "user@example.com"},
        )
    )
    identity = await verify_facebook_access_token("f" * 32)
    assert identity == {
        "provider": "facebook",
        "provider_sub": "facebook-sub-1",
        "email": "user@example.com",
        "name": "User",
        "email_verified": True,
    }
    assert profile_route.called
