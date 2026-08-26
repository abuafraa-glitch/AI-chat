"""Secure social-token verification for Hajeen authentication.

The backend verifies provider-issued tokens server-side. Provider tokens and
app secrets are never logged or returned to clients.
"""
from __future__ import annotations

import os
from typing import Any, Dict, Iterable, Optional

import httpx


class SocialAuthError(ValueError):
    """Raised when a social token cannot be verified safely."""


def _csv_env(*names: str) -> set[str]:
    values: set[str] = set()
    for name in names:
        raw = os.getenv(name, "")
        values.update(item.strip() for item in raw.split(",") if item.strip())
    return values


def _require_claim(payload: Dict[str, Any], claim: str) -> str:
    value = payload.get(claim)
    if not isinstance(value, str) or not value.strip():
        raise SocialAuthError(f"Missing provider claim: {claim}")
    return value.strip()


async def verify_google_id_token(id_token: str) -> Dict[str, Any]:
    """Verify a Google ID token using Google's tokeninfo endpoint.

    ``tokeninfo`` performs signature and expiry validation. We additionally
    validate the audience against the configured web/Android client IDs and
    require a verified email before the account can be linked.
    """
    if not id_token or len(id_token) > 8192:
        raise SocialAuthError("Invalid Google ID token")
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(
                "https://oauth2.googleapis.com/tokeninfo",
                params={"id_token": id_token},
            )
    except httpx.HTTPError as exc:
        raise SocialAuthError("Google verification unavailable") from exc
    if response.status_code != 200:
        raise SocialAuthError("Google token verification failed")
    try:
        claims = response.json()
    except ValueError as exc:
        raise SocialAuthError("Invalid Google verification response") from exc
    if not isinstance(claims, dict):
        raise SocialAuthError("Invalid Google verification response")

    audiences = _csv_env("GOOGLE_CLIENT_ID", "GOOGLE_WEB_CLIENT_ID", "GOOGLE_ANDROID_CLIENT_ID")
    audience = claims.get("aud")
    if audiences and audience not in audiences:
        raise SocialAuthError("Google token audience mismatch")
    if claims.get("email_verified") not in (True, "true", "True"):
        raise SocialAuthError("Google email is not verified")

    subject = _require_claim(claims, "sub")
    email = _require_claim(claims, "email").lower()
    return {
        "provider": "google",
        "provider_sub": subject,
        "email": email,
        "name": (claims.get("name") or claims.get("given_name") or email.split("@", 1)[0]).strip(),
        "email_verified": True,
    }


async def verify_facebook_access_token(access_token: str) -> Dict[str, Any]:
    """Verify a Facebook user access token against Hajeen's Meta app."""
    if not access_token or len(access_token) > 8192:
        raise SocialAuthError("Invalid Facebook access token")
    app_id = os.getenv("FACEBOOK_APP_ID", "").strip()
    app_secret = os.getenv("FACEBOOK_APP_SECRET", "").strip()
    if not app_id or not app_secret:
        raise SocialAuthError("Facebook verification is not configured")
    app_access_token = f"{app_id}|{app_secret}"

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            debug_response = await client.get(
                "https://graph.facebook.com/debug_token",
                params={"input_token": access_token, "access_token": app_access_token},
            )
            if debug_response.status_code != 200:
                raise SocialAuthError("Facebook token verification failed")
            debug_payload = debug_response.json()
            token_data = debug_payload.get("data", {}) if isinstance(debug_payload, dict) else {}
            if not token_data.get("is_valid") or str(token_data.get("app_id")) != app_id:
                raise SocialAuthError("Invalid Facebook token or app mismatch")

            user_response = await client.get(
                "https://graph.facebook.com/me",
                params={"fields": "id,name,email", "access_token": access_token},
            )
    except SocialAuthError:
        raise
    except (httpx.HTTPError, ValueError) as exc:
        raise SocialAuthError("Facebook verification unavailable") from exc

    if user_response.status_code != 200:
        raise SocialAuthError("Facebook profile verification failed")
    try:
        profile = user_response.json()
    except ValueError as exc:
        raise SocialAuthError("Invalid Facebook profile response") from exc
    if not isinstance(profile, dict):
        raise SocialAuthError("Invalid Facebook profile response")

    subject = _require_claim(profile, "id")
    email = profile.get("email")
    if not isinstance(email, str) or "@" not in email:
        raise SocialAuthError("Facebook did not provide a usable email")
    return {
        "provider": "facebook",
        "provider_sub": subject,
        "email": email.strip().lower(),
        "name": (profile.get("name") or email.split("@", 1)[0]).strip(),
        # Facebook's /me email is treated as verified only after token/app validation.
        "email_verified": True,
    }


def configured_social_providers() -> Iterable[str]:
    providers: list[str] = []
    if _csv_env("GOOGLE_CLIENT_ID", "GOOGLE_WEB_CLIENT_ID", "GOOGLE_ANDROID_CLIENT_ID"):
        providers.append("google")
    if os.getenv("FACEBOOK_APP_ID") and os.getenv("FACEBOOK_APP_SECRET"):
        providers.append("facebook")
    return providers
