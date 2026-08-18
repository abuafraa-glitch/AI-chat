"""Section 7.6 — RAG Pipeline كامل."""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass, field
from typing import Dict, Optional

from brain.prompts.unified_prompt_builder import PromptMode, UnifiedPromptBuilder
from services.rag.citation_manager import CitationManager
from services.rag.context_builder import ContextBuilder
from services.rag.prompt_builder import PromptBuilder, PromptTemplate
from services.rag.response_formatter import FormattedResponse, ResponseFormatter
from services.retrieval.base_retriever import BaseRetriever
from services.retrieval.context_assembler import ContextAssembler

logger = logging.getLogger(__name__)


@dataclass
class RAGRequest:
    """طلب RAG."""
    query: str
    top_k: int = 5
    language: str = "ar"
    template: Optional[PromptTemplate] = None
    filter_metadata: Optional[Dict] = None
    max_context_tokens: int = 2000
    retrieval_mode: str = "semantic"


@dataclass
class RAGResponse:
    """استجابة RAG كاملة."""
    request: RAGRequest
    formatted: FormattedResponse
    retrieval_result: Optional[object] = None
    total_ms: float = 0.0
    stage_timings: Dict = field(default_factory=dict)
    retrieval_mode: str = "semantic"

    def to_dict(self) -> dict:
        return {
            "query": self.request.query,
            "total_ms": round(self.total_ms, 2),
            "stage_timings": {k: round(v, 2) for k, v in self.stage_timings.items()},
            "retrieval": {
                "mode": self.retrieval_mode,
                "count": getattr(self.retrieval_result, "total_retrieved", 0),
                "retriever": getattr(self.retrieval_result, "retriever_name", None),
                "metadata": getattr(self.retrieval_result, "metadata", {}),
            },
            **self.formatted.to_dict(),
        }


class RAGPipeline:
    """
    RAG Pipeline كامل — من الاستعلام إلى الـ prompt الجاهز للـ LLM.

    التدفق:
        RAGRequest
          ↓ Retriever     → RetrievalResult
          ↓ ContextAssembler → AssembledContext
          ↓ ContextBuilder   → BuiltContext
          ↓ CitationManager  → Citations
          ↓ PromptBuilder    → BuiltPrompt
          ↓ ResponseFormatter → RAGResponse
    """

    def __init__(
        self,
        retriever: BaseRetriever,
        context_assembler: Optional[ContextAssembler] = None,
        context_builder: Optional[ContextBuilder] = None,
        prompt_builder: Optional[PromptBuilder] = None,
        unified_prompt_builder: Optional[UnifiedPromptBuilder] = None,
        response_formatter: Optional[ResponseFormatter] = None,
        retrieval_mode: Optional[str] = None,
    ):
        self.retriever = retriever
        inferred_mode = (
            "hybrid" if type(retriever).__name__ == "HybridRetriever" else "semantic"
        )
        self.retrieval_mode = retrieval_mode or inferred_mode
        if self.retrieval_mode not in {"semantic", "hybrid"}:
            raise ValueError(f"Unsupported retrieval mode: {self.retrieval_mode}")
        self.assembler = context_assembler or ContextAssembler(max_context_chars=6000)
        self.ctx_builder = context_builder or ContextBuilder(max_tokens=2000)
        # UnifiedPromptBuilder is the sole production prompt authority.
        # prompt_builder remains accepted only for source compatibility.
        self.prompt_builder = prompt_builder
        self.unified_prompt_builder = unified_prompt_builder or UnifiedPromptBuilder()
        self.formatter = response_formatter or ResponseFormatter()

    async def run(self, request: RAGRequest) -> RAGResponse:
        """تنفيذ RAG pipeline كامل."""
        t_total = time.perf_counter()
        timings = {}

        if not request.query or not request.query.strip():
            raise ValueError("RAG query must not be empty")
        if request.top_k < 1:
            raise ValueError("RAG top_k must be positive")
        if request.retrieval_mode not in {"semantic", "hybrid"}:
            raise ValueError(f"Unsupported retrieval mode: {request.retrieval_mode}")

        # The configured retriever is authoritative; request metadata cannot
        # claim a mode that was not instantiated by startup/dependency injection.
        effective_mode = self.retrieval_mode

        # 1. Retrieval
        t0 = time.perf_counter()
        retrieval_result = await self.retriever.retrieve(
            query=request.query,
            top_k=request.top_k,
            filter_metadata=request.filter_metadata,
        )
        timings["retrieval_ms"] = (time.perf_counter() - t0) * 1000

        # 2. Context Assembly
        t0 = time.perf_counter()
        assembled = self.assembler.assemble(retrieval_result)
        timings["assembly_ms"] = (time.perf_counter() - t0) * 1000

        # 3. Context Building (token limit)
        t0 = time.perf_counter()
        self.ctx_builder.max_tokens = request.max_context_tokens
        built_context = self.ctx_builder.build(assembled)
        timings["context_build_ms"] = (time.perf_counter() - t0) * 1000

        # 4. Citations
        t0 = time.perf_counter()
        citation_manager = CitationManager()
        citation_manager.add_from_chunks(built_context.raw_chunks)
        citations = citation_manager.to_dict_list()
        timings["citation_ms"] = (time.perf_counter() - t0) * 1000

        # 5. Prompt Building
        t0 = time.perf_counter()
        canonical_prompt = self.unified_prompt_builder.build(
            request.query,
            mode=PromptMode.RAG,
            context=built_context.formatted_text,
            language=request.language,
        )
        prompt_text = canonical_prompt.text
        timings["prompt_build_ms"] = (time.perf_counter() - t0) * 1000

        # 6. Response Formatting
        formatted = self.formatter.format(
            query=request.query,
            context_text=built_context.formatted_text,
            prompt=prompt_text,
            citations=citations,
            retrieval_ms=timings["retrieval_ms"],
        )
        formatted.metadata.update({
            "retrieval_mode": effective_mode,
            "retriever": getattr(retrieval_result, "retriever_name", None),
            "retrieval_count": getattr(retrieval_result, "total_retrieved", 0),
            "retrieval_metadata": getattr(retrieval_result, "metadata", {}),
        })

        total_ms = (time.perf_counter() - t_total) * 1000
        logger.info(
            f"RAG pipeline: '{request.query[:50]}' → "
            f"{len(citations)} مصادر في {total_ms:.1f}ms"
        )

        return RAGResponse(
            request=request,
            formatted=formatted,
            retrieval_result=retrieval_result,
            total_ms=total_ms,
            stage_timings=timings,
            retrieval_mode=effective_mode,
        )

    async def quick_context(self, query: str, top_k: int = 5) -> str:
        """استرجاع سريع للـ context كنص فقط."""
        result = await self.run(RAGRequest(query=query, top_k=top_k))
        return result.formatted.context_used
