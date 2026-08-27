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
