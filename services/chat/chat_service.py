"""
ChatService (Adapter) — خدمة الدردشة الرئيسية
=============================================
تم تحديث الخدمة لتستخدم UnifiedMemoryInterface حصرياً.
تم إزالة أي تعامل مباشر مع SessionManager أو أي كتابة مستقلة للذاكرة.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from dataclasses import dataclass, field
from typing import Any, AsyncGenerator, Dict, List, Optional

from brain.brain_v3 import BrainRequest, BrainResponse, HajeenBrainV3, get_brain_v3
from brain.memory.unified_interface import get_unified_memory
from core.llm.base import LLMStreamChunk

from .citation_injector import CitationInjector

logger = logging.getLogger(__name__)


@dataclass
class ChatRequest:
    """طلب محادثة."""
    message: str
    session_id: Optional[str] = None
    language: str = "ar"
    use_rag: bool = True
    stream: bool = False
    top_k: int = 5
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None
    model: Optional[str] = None
    system_prompt: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class ChatResponse:
    """استجابة المحادثة."""
    content: str
    session_id: str
    turn_id: str
    model: str
    provider: str
    sources: List[Dict[str, Any]]
    latency_ms: float
    tokens_used: int
    language: str = "ar"
    cached: bool = False
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "response": self.content,
            "session_id": self.session_id,
            "turn_id": self.turn_id,
            "model": self.model,
            "provider": self.provider,
            "sources": self.sources,
            "latency_ms": round(self.latency_ms, 2),
            "tokens_used": self.tokens_used,
            "language": self.language,
        }


class ChatService:
    """
    خدمة الدردشة الرئيسية (Adapter).
    تستخدم UnifiedMemoryInterface كمصدر وحيد للذاكرة.
    """

    def __init__(
        self,
        brain: Optional[HajeenBrainV3] = None,
        rag_pipeline: Optional[Any] = None,
        citation_injector: Optional[CitationInjector] = None,
        inference_engine: Optional[Any] = None,
    ):
        self._brain = brain
        self._inference_engine = inference_engine
        self._rag = rag_pipeline
        self.citation_injector = citation_injector or CitationInjector()
        self._initialized = False
        self._unified_memory = get_unified_memory()

    async def initialize(self) -> None:
        if self._initialized:
            return
        if self._inference_engine is not None:
            await self._inference_engine.initialize()
        else:
            self._brain = self._brain or await get_brain_v3()
        await self._unified_memory.initialize()
        self._initialized = True
        logger.info("ChatService initialized with UnifiedMemoryInterface (SSOT Mode)")

    async def chat(self, request: ChatRequest) -> ChatResponse:
        """تنفيذ محادثة كاملة عبر HajeenBrainV3."""
        if not self._initialized:
            await self.initialize()

        turn_id = str(uuid.uuid4())
        session_id = request.session_id or str(uuid.uuid4())

        if self._inference_engine is not None:
            history = await self._unified_memory.get_context(session_id, max_messages=20)
            messages = history + [{"role": "user", "content": request.message}]
            processed = await self._inference_engine.infer(
                messages=messages,
                model=request.model,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                session_id=session_id,
            )
            await self._unified_memory.add_message(session_id, "user", request.message, request.metadata)
            await self._unified_memory.add_message(session_id, "assistant", processed.cleaned_content, {"turn_id": turn_id})
            return ChatResponse(
                content=processed.cleaned_content,
                session_id=session_id,
                turn_id=turn_id,
                model=processed.model,
                provider=processed.provider,
                sources=self.citation_injector.format_citations_for_api(processed.citations),
                latency_ms=processed.latency_ms,
                tokens_used=processed.total_tokens,
                language=request.language,
            )

        # 1. Prepare BrainRequest
        brain_request = BrainRequest(
            request_id=turn_id,
            user_message=request.message,
            session_id=session_id,
            context={
                "language": request.language,
                "use_rag": request.use_rag,
                "temperature": request.temperature,
                "max_tokens": request.max_tokens,
                "model": request.model,
                "top_k": request.top_k,
                "system_prompt": request.system_prompt,
            },
            stream=False,
            max_tokens=request.max_tokens or 2048,
            temperature=request.temperature or 0.7,
            force_model=request.model,
        )

        # 2. Process through Brain (الذي يكتب بدوره في MemoryFabric)
        brain_response: BrainResponse = await self._brain.process(brain_request)

        # 3. Extract results
        final_content = brain_response.content
        model_used = brain_response.model_used
        provider_used = brain_response.policy_decision
        sources = brain_response.trace.execution.get("rag_sources", [])
        tokens_used = brain_response.trace.tokens_used
        latency_ms = brain_response.trace.total_latency_ms

        # ملاحظة: لم نعد نكتب في SessionManager هنا. 
        # الكتابة تمت بالفعل داخل Brain -> MemoryFabric.
        # وإذا احتجنا كتابة إضافية، نستخدم UnifiedMemoryInterface.
        
        logger.info(
            "Chat turn (SSOT): session=%s tokens=%d latency=%.1fms",
            session_id, tokens_used, latency_ms,
        )

        return ChatResponse(
            content=final_content,
            session_id=session_id,
            turn_id=turn_id,
            model=model_used,
            provider=provider_used,
            sources=self.citation_injector.format_citations_for_api(sources),
            latency_ms=latency_ms,
            tokens_used=tokens_used,
            language=request.language,
        )

    async def stream_chat(
        self,
        request: ChatRequest,
    ) -> AsyncGenerator[LLMStreamChunk, None]:
        """محادثة مع native streaming عبر HajeenBrainV3."""
        if not self._initialized:
            await self.initialize()

        session_id = request.session_id or str(uuid.uuid4())
        stream_id = str(uuid.uuid4())
        collected: List[str] = []
        completed = False

        if self._inference_engine is not None:
            history = await self._unified_memory.get_context(session_id, max_messages=20)
            messages = history + [{"role": "user", "content": request.message}]
            async for chunk in self._inference_engine.stream_infer(
                messages=messages,
                model=request.model,
                temperature=request.temperature,
                max_tokens=request.max_tokens,
                session_id=session_id,
                stream_id=stream_id,
            ):
                if not isinstance(chunk, LLMStreamChunk):
                    raise RuntimeError("InferenceEngine returned a non-native stream chunk")
                if chunk.event_type == "delta" and chunk.delta:
                    collected.append(chunk.delta)
                elif chunk.event_type == "finish":
                    completed = True
                yield chunk
            if completed:
                await self._unified_memory.add_message(session_id, "user", request.message, request.metadata)
                await self._unified_memory.add_message(session_id, "assistant", "".join(collected), {"stream_id": stream_id})
            return

        brain_request = BrainRequest(
            request_id=stream_id,
            user_message=request.message,
            session_id=session_id,
            context={
                "language": request.language,
                "use_rag": request.use_rag,
                "temperature": request.temperature,
                "max_tokens": request.max_tokens,
                "model": request.model,
                "top_k": request.top_k,
                "system_prompt": request.system_prompt,
                "stream": True,
            },
            stream=True,
            max_tokens=request.max_tokens or 2048,
            temperature=request.temperature or 0.7,
            force_model=request.model,
        )

        try:
            async for chunk in self._brain.stream(brain_request):
                if not isinstance(chunk, LLMStreamChunk):
                    raise RuntimeError("Brain returned a non-native stream chunk")
                if chunk.event_type == "delta" and chunk.delta:
                    collected.append(chunk.delta)
                elif chunk.event_type == "finish":
                    completed = True
                elif chunk.event_type == "error":
                    completed = False
                yield chunk
            if completed:
                await self._unified_memory.add_message(session_id, "user", request.message, request.metadata)
                await self._unified_memory.add_message(session_id, "assistant", "".join(collected), {"stream_id": stream_id})
        except asyncio.CancelledError:
            raise
        except Exception as e:
            yield LLMStreamChunk(
                delta="",
                event_type="error",
                provider="chat_service",
                request_id=stream_id,
                metadata={"error": str(e)},
            )

    def get_session_info(self, session_id: str) -> Optional[Dict[str, Any]]:
        """معلومات جلسة محادثة (عبر الواجهة الموحدة)."""
        # للحفاظ على التوافقية، نستخدم الواجهة الموحدة لجلب البيانات
        stats = self._unified_memory.get_stats()
        return {"session_id": session_id, "source": "MemoryFabric", "stats": stats}


# Singleton
_chat_service: Optional[ChatService] = None

def get_chat_service() -> ChatService:
    global _chat_service
    if _chat_service is None:
        _chat_service = ChatService()
    return _chat_service
