"""Phase 2 integration contracts.

The provider below is a test-only deterministic adapter. It is explicitly
registered on an isolated ModelRouter and is never part of production startup.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import AsyncGenerator

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


from brain.brain_v3 import BrainRequest, HajeenBrainV3
from brain.model_router import ModelRouter
from core.llm.base import LLMResponse, LLMStreamChunk, LLMRequest


@dataclass
class VerifiedProvider:
    """Test-only provider implementing the native provider contract."""

    text: str = "verified phase2 response"
    _initialized: bool = False

    async def initialize(self) -> None:
        self._initialized = True

    async def complete(self, request: LLMRequest) -> LLMResponse:
        return LLMResponse(
            content=self.text,
            model=request.model or "hajeen-v1",
            provider="local",
            prompt_tokens=sum(len(m.content.split()) for m in request.messages),
            completion_tokens=len(self.text.split()),
            total_tokens=sum(len(m.content.split()) for m in request.messages) + len(self.text.split()),
            request_id=request.request_id,
        )

    async def stream(self, request: LLMRequest) -> AsyncGenerator[LLMStreamChunk, None]:
        for index, token in enumerate(self.text.split()):
            yield LLMStreamChunk(
                delta=(" " if index else "") + token,
                index=index,
                model=request.model,
                )
        yield LLMStreamChunk(delta="", index=len(self.text.split()), finish_reason="stop")

    async def health_check(self) -> bool:
        return True


class FailingProvider(VerifiedProvider):
    async def complete(self, request: LLMRequest) -> LLMResponse:
        raise RuntimeError("provider unavailable")

    async def stream(self, request: LLMRequest) -> AsyncGenerator[LLMStreamChunk, None]:
        raise RuntimeError("provider unavailable")
        yield  # pragma: no cover


def make_router(provider=None) -> ModelRouter:
    router = ModelRouter(prefer_local=False)
    router.register_provider("hajeen-local", provider or VerifiedProvider())
    return router


def test_api_chat_delegates_to_brain_and_router():
    from api.v1.ai.router import router as ai_router

    app = FastAPI()
    brain = HajeenBrainV3()
    brain.model_router = make_router()
    app.state.brain = brain
    app.include_router(ai_router, prefix="/ai")

    with TestClient(app) as client:
        response = client.post(
            "/ai/chat",
            json={"message": "hello", "use_rag": False, "session_id": "api-phase2"},
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is True
    assert payload["response"] == "verified phase2 response"
    assert payload["provider"] == "local"


@pytest.mark.asyncio
async def test_external_provider_exposes_native_contract_without_fake_fallback():
    from core.llm.base import LLMConfig
    from core.llm.providers.ollama_provider import OllamaProvider

    provider = OllamaProvider(LLMConfig(provider="ollama", model="missing"))
    assert callable(provider.complete)
    assert callable(provider.stream)
    assert callable(provider.health_check)


@pytest.mark.asyncio
async def test_router_uses_explicit_registered_provider():
    result = await make_router().route([{"role": "user", "content": "hello"}], budget_tokens=64)
    assert result.success and result.provider == "local"
    assert result.response == "verified phase2 response"


@pytest.mark.asyncio
async def test_router_rejects_unknown_forced_model():
    result = await make_router().route([{"role": "user", "content": "hello"}], force_model="missing")
    assert not result.success and result.response == ""
    assert result.metadata["fail_closed"] is True


@pytest.mark.asyncio
async def test_router_does_not_fabricate_after_provider_failure():
    result = await make_router(FailingProvider()).route([{"role": "user", "content": "hello"}], budget_tokens=64)
    assert not result.success and result.response == ""
    assert result.metadata["fail_closed"] is True


@pytest.mark.asyncio
async def test_router_native_stream_contract():
    chunks = [chunk async for chunk in make_router().stream([{"role": "user", "content": "hello"}], budget_tokens=64)]
    assert chunks and all(isinstance(chunk, LLMStreamChunk) for chunk in chunks)
    assert "verified phase2 response" == "".join(chunk.delta for chunk in chunks).strip()
    assert chunks[-1].finish_reason == "stop"


@pytest.mark.asyncio
async def test_router_model_listing_reports_registered_health():
    models = await make_router().list_available_models()
    local = next(item for item in models if item["key"] == "hajeen-local")
    assert local["available"] is True and local["health"] is True


def test_model_router_is_the_explicit_selection_authority():
    router = make_router()
    assert router.models and callable(router.select_model)
    assert not hasattr(router, "llm_manager")


@pytest.mark.asyncio
async def test_brain_process_uses_router_and_stores_successful_turn():
    brain = HajeenBrainV3()
    brain.model_router = make_router()
    response = await brain.process(BrainRequest(
        request_id="phase2-process",
        session_id="phase2-session-success",
        user_message="hello",
        context={"use_rag": False},
        max_tokens=64,
    ))
    assert response.content == "verified phase2 response"
    assert response.trace.provider == "local"
    assert response.trace.execution["prompt_builder"] == "UnifiedPromptBuilder"
    messages = brain.memory.get_conversation("phase2-session-success").get_window()
    assert [message["role"] for message in messages[-2:]] == ["user", "assistant"]


@pytest.mark.asyncio
async def test_brain_fails_closed_without_fake_content():
    brain = HajeenBrainV3()
    brain.model_router = make_router(FailingProvider())
    with pytest.raises(RuntimeError, match="No verified model route available"):
        await brain.process(BrainRequest(
            request_id="phase2-failure",
            session_id="phase2-session-failure",
            user_message="hello",
            context={"use_rag": False},
            max_tokens=64,
        ))
    messages = brain.memory.get_conversation("phase2-session-failure").get_window()
    assert [message["role"] for message in messages] == ["user"]


@pytest.mark.asyncio
async def test_brain_native_stream_returns_provider_chunks_and_sentinel():
    brain = HajeenBrainV3()
    brain.model_router = make_router()
    request = BrainRequest(
        request_id="phase2-stream",
        session_id="phase2-session-stream",
        user_message="hello",
        context={"use_rag": False},
        stream=True,
        max_tokens=64,
    )
    chunks = [chunk async for chunk in brain.stream(request)]
    assert chunks and all(isinstance(chunk, LLMStreamChunk) for chunk in chunks)
    assert "verified phase2 response" == "".join(chunk.delta for chunk in chunks).strip()
    assert brain.memory.get_conversation("phase2-session-stream").get_window()[-1]["role"] == "assistant"


@pytest.mark.asyncio
async def test_brain_stream_cancellation_does_not_persist_assistant_content():
    import asyncio

    class CancellableProvider(VerifiedProvider):
        async def stream(self, request: LLMRequest) -> AsyncGenerator[LLMStreamChunk, None]:
            yield LLMStreamChunk(delta="partial", index=0, model=request.model)
            await asyncio.sleep(60)

    brain = HajeenBrainV3()
    brain.model_router = make_router(CancellableProvider())
    request = BrainRequest(
        request_id="phase2-stream-cancel",
        session_id="phase2-session-stream-cancel",
        user_message="hello",
        context={"use_rag": False},
        stream=True,
        max_tokens=64,
    )

    task = asyncio.create_task(_collect_stream(brain, request))
    await asyncio.sleep(0)
    task.cancel()
    with pytest.raises(asyncio.CancelledError):
        await task
    messages = brain.memory.get_conversation("phase2-session-stream-cancel").get_window()
    assert [message["role"] for message in messages] == ["user"]


async def _collect_stream(brain, request):
    return [chunk async for chunk in brain.stream(request)]


@pytest.mark.asyncio
async def test_brain_stream_failure_does_not_persist_assistant_content():
    brain = HajeenBrainV3()
    brain.model_router = make_router(FailingProvider())
    request = BrainRequest(
        request_id="phase2-stream-failure",
        session_id="phase2-session-stream-failure",
        user_message="hello",
        context={"use_rag": False},
        stream=True,
        max_tokens=64,
    )
    with pytest.raises(RuntimeError):
        _ = [chunk async for chunk in brain.stream(request)]
    messages = brain.memory.get_conversation("phase2-session-stream-failure").get_window()
    assert [message["role"] for message in messages] == ["user"]


@pytest.mark.asyncio
async def test_rag_is_required_when_requested_instead_of_silent_bypass():
    brain = HajeenBrainV3()
    brain.model_router = make_router()
    with pytest.raises(RuntimeError, match="canonical RAGPipeline"):
        await brain.process(BrainRequest(
            request_id="phase2-rag-required",
            session_id="phase2-session-rag-required",
            user_message="hello",
            context={"use_rag": True},
            max_tokens=64,
        ))


@pytest.mark.asyncio
async def test_router_forced_registered_model_overrides_local_preference():
    router = ModelRouter(prefer_local=True)
    provider = VerifiedProvider(text="forced")
    router.register_provider("hajeen-local", provider)
    result = await router.route(
        [{"role": "user", "content": "hello"}],
        force_model="hajeen-v1",
        budget_tokens=64,
    )
    assert result.success and result.model_id == "hajeen-local"


@pytest.mark.asyncio
async def test_hajeen_provider_health_is_false_without_checkpoint():
    from core.llm.providers.hajeen_provider import HajeenLLMProvider
    from core.llm.base import LLMConfig

    provider = HajeenLLMProvider(LLMConfig(provider="hajeen", model="hajeen-v1", extra={"model_path": "/path/that/does/not/exist"}))
    with pytest.raises(Exception, match="checkpoint is unavailable"):
        await provider.initialize()
    assert await provider.health_check() is False
