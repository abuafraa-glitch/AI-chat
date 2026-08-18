from __future__ import annotations

import asyncio
import json
import logging
import uuid
from typing import Any, AsyncGenerator, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from api.v1.ai.embeddings import router as embeddings_router
from api.v1.ai.health import router as health_router
from api.v1.ai.rerank import router as rerank_router
from brain.brain_v3 import (
    BrainRequest,
    BrainResponse,
    RequestType,
)
from core.llm.base import LLMStreamChunk
from hajeen_model.evaluation.evaluation_framework import EvaluationFramework

logger = logging.getLogger(__name__)

router = APIRouter()

# ── Mount sub-routers (only those not directly handled by Brain) ────────────────
router.include_router(embeddings_router, tags=["Embeddings"])
router.include_router(rerank_router, tags=["Rerank"])
router.include_router(health_router, tags=["Health"])


# ── Request/Response Schemas ──────────────────────────────────────────────────

class MessageSchema(BaseModel):
    role: str = Field(..., pattern="^(system|user|assistant)$")
    content: str = Field(..., min_length=1)


class ChatRequestSchema(BaseModel):
    message: str = Field(..., min_length=1, max_length=10000)
    session_id: Optional[str] = None
    language: str = "ar"
    use_rag: bool = True
    temperature: Optional[float] = Field(None, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(None, ge=1, le=4096)
    model: Optional[str] = None
    top_k: int = Field(5, ge=1, le=20)
    retrieval_mode: str = Field("semantic", pattern="^(semantic|hybrid)$")
    system_prompt: Optional[str] = None # Added system_prompt to schema


class CompletionRequestSchema(BaseModel):
    messages: List[MessageSchema] = Field(..., min_items=1)
    model: Optional[str] = None
    temperature: float = Field(0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(1024, ge=1, le=4096)
    stream: bool = False
    session_id: Optional[str] = None


class RAGQuerySchema(BaseModel):
    query: str = Field(..., min_length=1, max_length=5000)
    top_k: int = Field(5, ge=1, le=20)
    language: str = "ar"
    use_llm: bool = True
    temperature: Optional[float] = Field(None, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(None, ge=1, le=2048)
    retrieval_mode: str = Field("semantic", pattern="^(semantic|hybrid)$")


# ── POST /chat ─────────────────────────────────────────────────────────────────

@router.post("/chat", summary="محادثة AI موحدة عبر HajeenBrainV3", tags=["AI"])
async def chat(
    body: ChatRequestSchema,
    request: Request,
) -> Dict[str, Any]:
    """
    محادثة كاملة موحدة عبر HajeenBrainV3.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")

    brain_request = BrainRequest(
        request_id=f"chat_{uuid.uuid4().hex[:12]}",
        user_message=body.message,
        session_id=body.session_id or str(uuid.uuid4()),
        context={
            "language": body.language,
            "use_rag": body.use_rag,
            "temperature": body.temperature,
            "max_tokens": body.max_tokens,
            "model": body.model,
            "top_k": body.top_k,
            "retrieval_mode": body.retrieval_mode,
            "system_prompt": body.system_prompt,
        },
        stream=False,
        max_tokens=body.max_tokens or 2048,
        temperature=body.temperature or 0.7,
        force_model=body.model,
    )

    try:
        brain_response: BrainResponse = await brain.process(brain_request)
        return {
            "success": True,
            "response": brain_response.content,
            "session_id": brain_response.session_id,
            "turn_id": brain_response.request_id,
            "model": brain_response.model_used,
            "provider": brain_response.trace.provider,

            "sources": brain_response.trace.execution.get("rag_sources", []), # Assuming RAG sources are in trace
            "latency_ms": brain_response.trace.total_latency_ms,
            "tokens_used": brain_response.trace.tokens_used,
            "retrieval_mode": brain_response.trace.execution.get("rag_retrieval_mode"),
            "language": body.language,
        }
    except Exception as e:
        logger.error("Brain chat error: %s", e)
        raise HTTPException(status_code=500, detail=f"Brain chat error: {str(e)}")


# ── POST /chat/stream ──────────────────────────────────────────────────────────

@router.post("/chat/stream", summary="محادثة AI متدفقة عبر HajeenBrainV3", tags=["AI"])
async def chat_stream(
    body: ChatRequestSchema,
    request: Request,
) -> StreamingResponse:
    """
    محادثة متدفقة موحدة عبر HajeenBrainV3.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")

    stream_id = str(uuid.uuid4())
    brain_request = BrainRequest(
        request_id=stream_id,
        user_message=body.message,
        session_id=body.session_id or str(uuid.uuid4()),
        context={
            "language": body.language,
            "use_rag": body.use_rag,
            "temperature": body.temperature,
            "max_tokens": body.max_tokens,
            "model": body.model,
            "top_k": body.top_k,
            "retrieval_mode": body.retrieval_mode,
            "system_prompt": body.system_prompt,
            "stream": True,
        },
        stream=True,
        max_tokens=body.max_tokens or 2048,
        temperature=body.temperature or 0.7,
        force_model=body.model,
    )

    async def event_generator() -> AsyncGenerator[str, None]:
        completed = False
        try:
            async for chunk in brain.stream(brain_request):
                if not isinstance(chunk, LLMStreamChunk):
                    raise RuntimeError("Brain returned an invalid native stream chunk")
                if chunk.event_type == "start":
                    payload = {"event": "start", "id": brain_request.request_id, "model": chunk.model}
                elif chunk.event_type == "delta":
                    payload = {"event": "delta", "choices": [{"delta": {"content": chunk.delta}, "index": chunk.sequence}]}
                elif chunk.event_type == "finish" or chunk.finish_reason:
                    payload = {"event": "finish", "finish_reason": chunk.finish_reason or "stop", "metadata": chunk.metadata}
                    completed = True
                else:
                    raise RuntimeError(f"Unsupported native stream event: {chunk.event_type}")
                yield f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"
            if not completed:
                raise RuntimeError("Native stream ended without finish event")
            yield "data: [DONE]\n\n"
        except asyncio.CancelledError:
            raise
        except Exception as e:
            logger.error("Brain stream error: %s", e)
            yield f"data: {json.dumps({'event': 'error', 'error': str(e)}, ensure_ascii=False)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )


# ── POST /rag/query ────────────────────────────────────────────────────────────

@router.post("/rag/query", summary="RAG Query عبر HajeenBrainV3", tags=["AI", "RAG"])
async def rag_query(
    body: RAGQuerySchema,
    request: Request,
) -> Dict[str, Any]:
    """
    استعلام RAG كامل عبر HajeenBrainV3.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")

    brain_request = BrainRequest(
        request_id=f"rag_{uuid.uuid4().hex[:12]}",
        user_message=body.query,
        session_id=str(uuid.uuid4()), # RAG queries might not have a session_id
        context={
            "language": body.language,
            "use_rag": True,
            "temperature": body.temperature,
            "max_tokens": body.max_tokens,
            "top_k": body.top_k,
            "retrieval_mode": body.retrieval_mode,
        },
        request_type=RequestType.ANALYSIS, # Or a more appropriate type for RAG
        max_tokens=body.max_tokens or 2048,
        temperature=body.temperature or 0.7,
    )

    try:
        brain_response = await brain.process(brain_request)
        return {
            "success": True,
            "response": brain_response.content,
            "model": brain_response.model_used,
            "provider": brain_response.trace.provider,

            "sources": brain_response.trace.execution.get("rag_sources", []), # Assuming RAG sources are in trace
            "retrieval_mode": brain_response.trace.execution.get("rag_retrieval_mode"),
            "tokens_used": brain_response.trace.tokens_used,
            "latency_ms": brain_response.trace.total_latency_ms,
        }
    except Exception as e:
        logger.error("Brain RAG query error: %s", e)
        raise HTTPException(status_code=500, detail=f"Brain RAG query error: {str(e)}")


# ── GET /models ────────────────────────────────────────────────────────────────

@router.get("/models", summary="النماذج المتاحة", tags=["AI"])
async def list_models(request: Request) -> Dict[str, Any]:
    """
    قائمة النماذج والمزودين المتاحين.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
    models = await brain.model_router.list_available_models()
    return {"models": models, "routing_authority": "ModelRouter"}


# ── GET /chat/sessions/{session_id} ───────────────────────────────────────────

@router.get("/chat/sessions/{session_id}", summary="معلومات جلسة المحادثة عبر HajeenBrainV3", tags=["AI"])
async def get_session(session_id: str, request: Request) -> Dict[str, Any]:
    """
    الحصول على معلومات جلسة محادثة عبر HajeenBrainV3.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
    
    # Assuming HajeenBrainV3 has a method to get session info from MemoryFabric
    # This method needs to be implemented in MemoryFabric or exposed via Brain
    session_info = brain.memory.get_session_overview(session_id) # This method needs to be implemented in MemoryFabric
    if not session_info:
        raise HTTPException(404, f"Session '{session_id}' not found")
    return session_info


# ── POST /chat/sessions/{session_id}/clear ────────────────────────────────────

@router.post("/chat/sessions/{session_id}/clear", summary="مسح جلسة محادثة عبر HajeenBrainV3", tags=["AI"])
async def clear_session(session_id: str, request: Request) -> Dict[str, Any]:
    """
    مسح سجل جلسة محادثة عبر HajeenBrainV3.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")
    
    # Assuming HajeenBrainV3 has a method to clear session in MemoryFabric
    # This method needs to be implemented in MemoryFabric or exposed via Brain
    brain.memory.clear_session(session_id) # This method needs to be implemented in MemoryFabric
    return {
        "deleted": True,
        "session_id": session_id,
        "message": "Session cleared",
    }


# ── GET /ai/stats ──────────────────────────────────────────────────────────────

@router.get("/stats", summary="إحصائيات HajeenBrainV3", tags=["AI"])
async def ai_stats(request: Request) -> Dict[str, Any]:
    """
    إحصائيات شاملة لـ HajeenBrainV3.
    """
    brain = request.app.state.brain
    if brain is None:
        raise HTTPException(status_code=503, detail="HajeenBrainV3 not initialized")

    return brain.get_stats()

@router.post("/evaluate", summary="تشغيل إطار التقييم", tags=["AI"])
async def evaluate_model() -> Dict[str, Any]:
    """
    تشغيل إطار التقييم التلقائي وإرجاع تقرير مفصل.
    """
    eval_framework = EvaluationFramework()
    report = await eval_framework.evaluate_and_save_report()
    return report
