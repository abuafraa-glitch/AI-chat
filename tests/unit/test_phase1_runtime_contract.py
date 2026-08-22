"""Phase 1 runtime contract tests.

The provider below is a test-only double. It is never registered by production
startup and exists only to verify ModelRouter's public contract deterministically.
"""

import pytest

from brain.model_router import ModelRouter


class TestOnlyProvider:
    async def chat(self, prompt: str):
        return {"content": f"verified:{prompt}"}


@pytest.mark.asyncio
async def test_route_accepts_request_level_local_preference_and_selects_registered_provider():
    router = ModelRouter(prefer_local=False)
    router.register_provider("hajeen-local", TestOnlyProvider())

    result = await router.route(
        messages=[{"role": "user", "content": "hello"}],
        capability="general",
        budget_tokens=64,
        prefer_local=True,
    )

    assert result.success is True
    assert result.model_id == "hajeen-local"
    assert result.provider == "local"
    assert result.response == "verified:hello"


@pytest.mark.asyncio
async def test_unverified_local_provider_fails_closed_without_fabricated_response():
    router = ModelRouter(prefer_local=True)

    result = await router.route(
        messages=[{"role": "user", "content": "hello"}],
        capability="general",
        budget_tokens=64,
        prefer_local=True,
    )

    assert result.success is False
    assert result.response == ""
    assert result.provider == "none"
    assert result.error


def test_route_signature_preserves_model_provider_separation():
    router = ModelRouter(prefer_local=False)
    key = "hajeen-local"
    config = router._models[key]

    assert config.model_id == "Qwen/Qwen3-30B-A3B"
    assert config.provider == "local"
    assert config.model_id != config.provider
