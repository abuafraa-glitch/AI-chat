"""Regression tests for the unauthenticated social-login boundary."""

from security.middleware.auth_middleware import PUBLIC_PATHS


def test_social_auth_routes_are_public_for_initial_token_exchange() -> None:
    """OAuth provider tokens are exchanged before a Hajeen JWT exists."""
    assert "/api/v1/auth/google" in PUBLIC_PATHS
    assert "/api/v1/auth/facebook" in PUBLIC_PATHS


def test_protected_routes_are_not_accidentally_public() -> None:
    """The allow-list change must not weaken ordinary authenticated APIs."""
    assert "/api/v1/auth/me" not in PUBLIC_PATHS
    assert "/api/v1/ai/chat" not in PUBLIC_PATHS
