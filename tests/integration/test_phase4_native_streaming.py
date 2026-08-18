import asyncio

import pytest

from brain.model_router import ModelRouter
from core.llm.base import LLMStreamChunk


class ProviderNative:
    _initialized = True

    async def initialize(self):
        self._initialized = True

    async def stream(self, request):
        yield LLMStreamChunk(delta="مرحباً", index=1, event_type="delta")
        yield LLMStreamChunk(delta=" بك", index=2, event_type="delta")
        yield LLMStreamChunk(delta="", index=3, finish_reason="stop", event_type="finish")


class ProviderInvalid:
    _initialized = True

    async def stream(self, request):
        yield "not-a-native-chunk"


class ProviderSlow:
    _initialized = True

    async def stream(self, request):
        await asyncio.sleep(0.2)
        yield LLMStreamChunk(delta="late", index=1, event_type="delta")


async def collect(router, model_key="hajeen-local", timeout=1.0):
    return [
        chunk
        async for chunk in router.stream(
            [{"role": "user", "content": "اختبار"}],
            force_model=model_key,
            timeout=timeout,
            request_id="phase4-test",
        )
    ]


def make_router(provider):
    router = ModelRouter(prefer_local=True)
    router.register_provider("hajeen-local", provider)
    return router


@pytest.mark.asyncio
async def test_model_router_forwards_native_start_delta_finish():
    chunks = await collect(make_router(ProviderNative()))

    assert [chunk.event_type for chunk in chunks] == ["start", "delta", "delta", "finish"]
    assert "".join(chunk.delta for chunk in chunks) == "مرحباً بك"
    assert chunks[-1].finish_reason == "stop"
    assert all(chunk.provider == "local" for chunk in chunks)


@pytest.mark.asyncio
async def test_model_router_rejects_non_native_provider_chunks():
    with pytest.raises(RuntimeError, match="invalid stream chunk"):
        await collect(make_router(ProviderInvalid()))


@pytest.mark.asyncio
async def test_model_router_applies_idle_timeout_and_closes_stream():
    with pytest.raises(asyncio.TimeoutError):
        await collect(make_router(ProviderSlow()), timeout=0.01)


@pytest.mark.asyncio
async def test_model_router_is_fail_closed_for_unknown_forced_model():
    router = ModelRouter()
    with pytest.raises(RuntimeError, match="not registered"):
        await collect(router, model_key="unknown/model")
