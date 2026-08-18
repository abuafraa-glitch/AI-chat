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


class MemoryRecorder:
    def __init__(self):
        self.messages = []

    async def initialize(self):
        return None

    async def get_context(self, session_id, max_messages=20):
        return []

    async def add_message(self, session_id, role, content, metadata=None):
        self.messages.append((session_id, role, content, metadata or {}))


class BrainSuccessful:
    async def stream(self, request):
        yield LLMStreamChunk(delta="", event_type="start", request_id=request.request_id)
        yield LLMStreamChunk(delta="native response", event_type="delta", request_id=request.request_id)
        yield LLMStreamChunk(delta="", event_type="finish", finish_reason="stop", request_id=request.request_id)


class BrainFailed:
    async def stream(self, request):
        yield LLMStreamChunk(delta="partial", event_type="delta", request_id=request.request_id)
        yield LLMStreamChunk(delta="", event_type="error", request_id=request.request_id, metadata={"error": "provider failed"})


@pytest.mark.asyncio
async def test_chat_service_saves_memory_only_after_successful_finish():
    from services.chat.chat_service import ChatRequest, ChatService

    service = ChatService(brain=BrainSuccessful())
    memory = MemoryRecorder()
    service._unified_memory = memory
    service._initialized = True
    events = [event async for event in service.stream_chat(ChatRequest(message="سؤال"))]

    assert [event.event_type for event in events] == ["start", "delta", "finish"]
    assert [role for _, role, _, _ in memory.messages] == ["user", "assistant"]
    assert memory.messages[-1][2] == "native response"


@pytest.mark.asyncio
async def test_chat_service_does_not_save_memory_after_error():
    from services.chat.chat_service import ChatRequest, ChatService

    service = ChatService(brain=BrainFailed())
    memory = MemoryRecorder()
    service._unified_memory = memory
    service._initialized = True
    events = [event async for event in service.stream_chat(ChatRequest(message="سؤال"))]

    assert [event.event_type for event in events] == ["delta", "error"]
    assert memory.messages == []
