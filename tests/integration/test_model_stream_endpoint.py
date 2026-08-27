import pytest
from fastapi import FastAPI, Request

from api.v1.hajeen_model_router import ChatRequest, stream_chat
from core.llm.base import LLMStreamChunk


class FakeBrain:
    async def stream(self, request):
        yield LLMStreamChunk(
            delta="مرحبا",
            index=1,
            event_type="delta",
            request_id=request.request_id,
        )
        yield LLMStreamChunk(
            delta="",
            index=2,
            event_type="finish",
            finish_reason="stop",
            request_id=request.request_id,
        )


@pytest.mark.asyncio
async def test_model_stream_endpoint_relays_delta_and_finish_events():
    app = FastAPI()
    app.state.brain = FakeBrain()
    request = Request({"type": "http", "app": app})

    response = await stream_chat(ChatRequest(message="اختبار"), request)
    body = "".join([part async for part in response.body_iterator])

    assert '"event": "delta"' in body
    assert '"content": "مرحبا"' in body
    assert '"index": 1' in body
    assert '"event": "finish"' in body
    assert "[DONE]" in body
    assert '"event": "error"' not in body


def test_mobile_model_ids_normalize_to_registered_groq_key():
    from api.v1.compat_router import GROQ_RUNTIME_MODEL, _groq_model

    assert _groq_model("gpt-4o-mini") == GROQ_RUNTIME_MODEL
    assert _groq_model("openai/gpt-oss-20b") == GROQ_RUNTIME_MODEL
    assert _groq_model(None) == GROQ_RUNTIME_MODEL


def test_model_router_resolves_mobile_aliases_to_groq_key():
    from brain.model_router import GROQ_RUNTIME_MODEL_KEY, ModelRouter

    router = ModelRouter(prefer_local=False)
    assert router._resolve_key("gpt-4o-mini") == GROQ_RUNTIME_MODEL_KEY
    assert router._resolve_key("openai/gpt-oss-20b") == GROQ_RUNTIME_MODEL_KEY


@pytest.mark.asyncio
async def test_groq_provider_uses_extended_http_timeout(monkeypatch):
    import openai
    from core.llm.base import LLMConfig
    from core.llm.providers.openai_provider import OpenAIProvider

    captured = {}

    class FakeAsyncOpenAI:
        def __init__(self, **kwargs):
            captured.update(kwargs)

    monkeypatch.setattr(openai, "AsyncOpenAI", FakeAsyncOpenAI)
    monkeypatch.delenv("GROQ_HTTP_TIMEOUT_SECONDS", raising=False)
    provider = OpenAIProvider(LLMConfig(provider="groq", model="openai/gpt-oss-20b", api_key="test", api_base="https://api.groq.com/openai/v1"))
    await provider.initialize()

    assert captured["timeout"] == 120.0
    assert captured["max_retries"] == 1
