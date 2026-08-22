import asyncio

import pytest

from core.inference_engine.stream_handler import StreamHandler
from core.llm.base import LLMStreamChunk
from security.runtime_admission import AdmissionDenied, ExecutionContext, authorize_stream


def context():
    return ExecutionContext("req-1", "user-1", "tenant-a", "conv-1", "model-a")


def test_stream_authorization_rejects_cross_tenant_before_first_event():
    with pytest.raises(AdmissionDenied, match="cross_tenant_stream_denied"):
        authorize_stream(
            context(),
            conversation_tenant_id="tenant-b",
            model_verified=True,
            provider_available=True,
            authorized=True,
        )


def test_stream_authorization_rejects_unverified_model():
    with pytest.raises(AdmissionDenied, match="stream_model_not_verified"):
        authorize_stream(
            context(),
            conversation_tenant_id="tenant-a",
            model_verified=False,
            provider_available=True,
            authorized=True,
        )


def test_native_stream_has_start_and_finish_and_is_cleaned_up():
    async def source():
        yield LLMStreamChunk(delta="hello", index=0, request_id="req-1")
        yield LLMStreamChunk(delta="", event_type="finish", finish_reason="stop", index=1, request_id="req-1")

    async def run():
        handler = StreamHandler()
        chunks = [chunk async for chunk in handler.process_stream(source(), "req-1")]
        assert chunks[0].event_type == "start"
        assert any(chunk.event_type == "finish" for chunk in chunks)
        assert handler.get_session("req-1") is None

    asyncio.run(run())
