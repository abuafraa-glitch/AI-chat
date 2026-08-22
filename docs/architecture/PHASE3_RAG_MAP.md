# Phase 3 — RAG / Retrieval Map

## فصل المسؤوليات

| المسؤولية | المالك المرشح | الحالة |
|---|---|---|
| Public search API | `api/v1/search` | API/SECONDARY | public boundary وليست RAG implementation. |
| Retrieval orchestration | `core/retrieval/retrieval_engine.py` | CANONICAL FACADE CANDIDATE | يحتوي `RetrievalEngine`, hits, response. |
| Semantic retriever | `services/rag/retriever.py` | SECONDARY RETRIEVER | `SemanticRetriever` ونتائج retrieval. |
| Hybrid/vector/multi-query | `services/retrieval/*` | SPECIALIZED/SECONDARY | implementations متخصصة. |
| Vector store | `data_engine/storage/vector_store/` | STORAGE LAYER | لا يقرر orchestration. |
| Embeddings | `core/embeddings` و`data_engine/ai/embeddings` | UNKNOWN | تكرار وفشل تهيئة بيئي سابق. |
| Context/prompt | `services/rag/prompt_builder.py` | ADAPTER/SPECIALIZED | RAG context فقط. |
| Citations/evaluation | monitoring/search metrics وRAG services | SUPPORTING | يحتاج عقد citations موحد. |

## المسار المستهدف

`Brain → Retrieval Facade → Retriever → Vector Store → Context Builder → Citations`. لا يُعتبر search route وحده مالكاً لـRAG.

## القرار

`RetrievalEngine` هو أفضل facade مرشح، لكن الحالة `CANONICAL FACADE CANDIDATE` حتى يثبت استخدامه من Brain/Chat في Runtime Trace. لا حذف لأي retriever.


## مصادر الأدلة

- الالتزام المفحوص: `3268c262be9fb2fac9ed641d047857aa788e5566`.[1]
- الدليل الآلي: Import Graph وPhase 1/2 reports وRuntime Probes الموجودة في `docs/architecture/`.
- التصنيف المتحفظ: وجود الكود لا يساوي إثبات Runtime، ووجود اختبار وحدة لا يساوي إثبات E2E.

### References

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/3268c262be9fb2fac9ed641d047857aa788e5566
