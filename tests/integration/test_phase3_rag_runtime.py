"""Phase 3 acceptance tests for the canonical RAG runtime path.

These tests use the repository's real embedding model, FAISS store, search engine,
retrievers, reranker, context assembly, citation manager, and prompt builder.
The only isolated seam is model generation because no causal checkpoint is
available in the test environment; the test asserts the prompt/provider boundary
instead of fabricating a production answer.
"""
from __future__ import annotations

import os
import time
from pathlib import Path
from types import SimpleNamespace

import pytest

MODEL_PATH = Path("/home/ubuntu/.cache/hajeen-models/all-MiniLM-L6-v2")
pytestmark = pytest.mark.skipif(
    not MODEL_PATH.is_dir(),
    reason="real local all-MiniLM-L6-v2 checkpoint is unavailable",
)

os.environ.setdefault("HAJEEN_EMBEDDING_MODEL_PATH", str(MODEL_PATH))
os.environ.setdefault("HF_HUB_OFFLINE", "1")

from core.embeddings.embedding_manager import EmbeddingManager  # noqa: E402
from data_engine.storage.vector_store.base_vector_store import VectorEntry  # noqa: E402
from data_engine.storage.vector_store.faiss_client import FAISSVectorStore  # noqa: E402
from services.rag.rag_pipeline import RAGPipeline, RAGRequest  # noqa: E402
from services.retrieval.hybrid_retriever import HybridRetriever  # noqa: E402
from services.retrieval.vector_retriever import VectorRetriever  # noqa: E402
from services.search.semantic_search import SemanticSearchEngine  # noqa: E402


async def _build_pipeline(mode: str = "semantic") -> tuple[RAGPipeline, FAISSVectorStore]:
    manager = EmbeddingManager()
    documents = [
        ("oil-1", "energy-1", "النفط والغاز الطبيعي من مصادر الطاقة المهمة للاقتصاد.", "oil"),
        ("code-1", "software-1", "البرمجة تعتمد على الخوارزميات وهياكل البيانات.", "code"),
        ("solar-1", "energy-2", "الطاقة الشمسية تعتمد على الألواح والخلايا الضوئية.", "solar"),
    ]
    vectors = await manager.embed_batch([item[2] for item in documents])
    store = FAISSVectorStore(dimensions=manager.dimensions)
    store.add([
        VectorEntry(
            id=chunk_id,
            vector=embedding.vector,
            chunk_id=chunk_id,
            article_id=article_id,
            text=text,
            model_name=embedding.model_name,
            metadata={"title": label, "url": f"https://example.invalid/{label}", "label": label},
        )
        for (chunk_id, article_id, text, label), embedding in zip(documents, vectors)
    ])
    engine = SemanticSearchEngine(store, rerank=True, default_top_k=3)
    retriever = HybridRetriever(engine) if mode == "hybrid" else VectorRetriever(engine)
    return RAGPipeline(retriever=retriever), store


@pytest.mark.asyncio
async def test_real_embedding_vector_store_retrieval_and_provenance():
    pipeline, store = await _build_pipeline()
    assert store.stats().total_vectors == 3

    result = await pipeline.run(RAGRequest(query="ما أهمية النفط والغاز؟", top_k=2))
    assert result.retrieval_result.total_retrieved == 2
    assert result.retrieval_result.chunks[0]["article_id"] == "energy-1"
    assert result.formatted.citations[0]["chunk_id"] == "oil-1"
    assert result.formatted.citations[0]["rank"] == 1
    assert result.formatted.citations[0]["metadata"]["label"] == "oil"
    assert "النفط والغاز" in result.formatted.context_used
    assert "النفط والغاز" in result.formatted.prompt_ready
    assert result.stage_timings["retrieval_ms"] >= 0
    response_dict = result.to_dict()
    assert response_dict["retrieval"]["mode"] == "semantic"
    assert response_dict["retrieval"]["retriever"] == "VectorRetriever"


@pytest.mark.asyncio
async def test_hybrid_retriever_is_real_pipeline_option():
    pipeline, _ = await _build_pipeline(mode="hybrid")
    result = await pipeline.run(
        RAGRequest(query="النفط والغاز", top_k=2, retrieval_mode="hybrid")
    )
    assert result.retrieval_result.retriever_name == "HybridRetriever"
    assert result.retrieval_result.total_retrieved >= 1
    assert result.retrieval_result.chunks[0]["article_id"] == "energy-1"
    assert result.to_dict()["retrieval"]["mode"] == "hybrid"


@pytest.mark.asyncio
async def test_no_results_and_invalid_query_are_safe():
    pipeline, _ = await _build_pipeline()
    result = await pipeline.run(
        RAGRequest(
            query="موضوع غير موجود إطلاقاً",
            top_k=2,
            filter_metadata={"label": "does-not-exist"},
        )
    )
    assert result.retrieval_result.total_retrieved == 0
    assert result.formatted.citations == []
    assert result.formatted.context_used == ""
    with pytest.raises(ValueError, match="must not be empty"):
        await pipeline.run(RAGRequest(query="   "))


@pytest.mark.asyncio
async def test_real_rag_latency_measurements_are_recorded():
    pipeline, _ = await _build_pipeline()
    samples = []
    for _ in range(5):
        started = time.perf_counter()
        result = await pipeline.run(RAGRequest(query="النفط والغاز", top_k=2))
        samples.append((time.perf_counter() - started) * 1000)
        assert result.retrieval_result.total_retrieved >= 1
    samples.sort()
    p50 = samples[len(samples) // 2]
    p95 = samples[min(len(samples) - 1, int(len(samples) * 0.95))]
    assert p50 >= 0
    assert p95 >= p50
    assert all(result_value >= 0 for result_value in samples)


@pytest.mark.asyncio
async def test_failure_does_not_create_context_or_citations():
    class BrokenRetriever:
        async def retrieve(self, **kwargs):
            raise RuntimeError("vector store unavailable")

    pipeline = RAGPipeline(retriever=BrokenRetriever())
    with pytest.raises(RuntimeError, match="vector store unavailable"):
        await pipeline.run(RAGRequest(query="النفط والغاز"))


@pytest.mark.asyncio
async def test_brain_boundary_receives_rag_prompt_and_memory(monkeypatch):
    from brain.brain_v3 import BrainRequest, HajeenBrainV3

    pipeline, _ = await _build_pipeline()
    brain = HajeenBrainV3()
    brain.set_rag_pipeline(pipeline)
    seen = {}

    async def route(**kwargs):
        seen["messages"] = kwargs["messages"]
        return SimpleNamespace(
            success=True,
            response="إجابة اختبارية مبنية على السياق",
            model_id="test-boundary",
            provider="boundary-test",
            tokens_used=8,
            latency_ms=0.1,
            error=None,
        )

    monkeypatch.setattr(brain.model_router, "route", route)
    request = BrainRequest(
        request_id="phase3-boundary",
        user_message="ما أهمية النفط والغاز؟",
        session_id="phase3-session",
        context={"use_rag": True, "top_k": 2},
    )
    response = await brain.process(request)
    prompt_text = "\n".join(str(message.get("content", "")) for message in seen["messages"])
    assert "النفط والغاز" in prompt_text
    assert response.used_rag is True
    assert response.trace.execution["prompt_builder"] == "UnifiedPromptBuilder"
    assert response.trace.execution["rag_pipeline"] == "RAGPipeline"
    assert response.trace.reflection["stored_in_memory_fabric"] is True
