# Hajeen Architecture Ownership Map

> نطاق الملف: فرع `master` عند الالتزام `3268c262be9fb2fac9ed641d047857aa788e5566`. هذا الملف توثيقي فقط؛ لم تُنقل أو تُحذف أو تُعاد تسمية أي ملفات تشغيلية.

## حالات الإثبات

| الحالة | المعنى |
|---|---|
| `CODE_EXISTS` | يوجد كود أو عقد يمكن تحديده في المستودع. |
| `INTEGRATED` | توجد إحالات أو واجهة تربطه بطبقة أخرى في الكود. |
| `RUNTIME_PROVEN` | ثبت تشغيله فعلياً في اختبار تنفيذ أو مسار تشغيل. |
| `NOT_PROVEN` | لم يتوفر دليل تشغيل فعلي كافٍ في هذه المرحلة. |

## خريطة الملكية

| Component | Canonical Path | Owner | Public Interface | Callers / References | Runtime Used | Tests | Duplicates | Decision |
|---|---|---|---|---|---|---|---|---|
| API application | `api/main.py` | API | FastAPI app, startup/shutdown, `/health` | API routers, WebSocket | PARTIAL | PASS/PARTIAL | Multiple routers | KEEP; make lifecycle explicit later |
| AI chat API | `api/v1/ai/chat.py`, `api/v1/ai/router.py` | API/Conversation | `POST /chat`, `POST /chat/stream` | Flutter/client, API include | INTEGRATED | PARTIAL | Two chat route surfaces | KEEP one canonical route contract later |
| Authentication | `api/v1/auth/`, `security/auth/` | Security/Auth | Auth dependencies and token flow | API routes | INTEGRATED | PARTIAL | Possible overlap | KEEP; consolidate authority later |
| Authorization | `security/`, `api/dependencies.py` | Security | dependencies/policies | API and service layer | NOT_PROVEN | PARTIAL | Policy implementations | KEEP; prove tenant and resource isolation |
| Multi-tenant | `multi_tenant/` | Platform/Security | tenant context and isolation helpers | API/services | CODE_EXISTS | NOT_PROVEN | Possible service-level checks | KEEP; add isolation E2E |
| Conversations | `services/chat/chat_service.py` | Conversation | `ChatService`, `stream_chat` | `api/v1/ai/*`, WebSocket | INTEGRATED | PASS for chat unit tests | API and service chat paths | KEEP service as canonical orchestration boundary |
| BrainV3 | `brain/brain_v3.py` | Cognitive/Brain | `HajeenBrainV3`, `process`, `stream`, `get_brain_v3` | Chat service, AI API, WebSocket | INTEGRATED | 6 integration tests PASS | Legacy brain/evolution references | KEEP; retire compatibility paths later |
| Memory | `brain/memory/`, `core/memory/`, `services/memory/` | Memory | Multiple memory managers/fabrics | Brain, chat, RAG | PARTIAL | Chat memory tests PASS | YES | Keep one canonical implementation; consolidate later |
| RAG | `core/retrieval/`, `services/rag/`, `api/v1/search/` | Knowledge/RAG | retriever, context builder, citation flow | Brain, search API | PARTIAL | Unit RAG tests PASS | YES | KEEP; define one retrieval facade |
| Data ingestion | `data_engine/ingestion/` | Data Engine | connectors/crawlers/ingestion jobs | workers and data services | CODE_EXISTS | PARTIAL | Data service overlap | KEEP; document job entrypoints |
| Data cleaning | `data_engine/processing/` | Data Engine | cleaning/normalization processors | ingestion and embedding stages | CODE_EXISTS | PARTIAL | Processing service overlap | KEEP; add data lineage evidence |
| Embeddings | `data_engine/`, embedding services | Knowledge | embedding stage/provider | RAG/vector store | INTEGRATED | FAIL/PARTIAL at full collection | Multiple provider/cache paths | KEEP; fix model dependency initialization |
| Storage | `storage/`, `storage_data/`, `database/` | Platform/Data | repositories, object/storage adapters | files, conversations, services | PARTIAL | PARTIAL | YES | KEEP; separate DB/object/vector ownership |
| Model Registry | `core/model/model_registry.py` | Model | `register`, `register_verified_base`, `get_artifact`, `eligible_artifacts` | `brain/model_router.py`, learning lifecycle | INTEGRATED | 3 verified-base tests PASS | Possible legacy registries | KEEP canonical |
| Model Router | `brain/model_router.py` | Model | `ModelRouter`, route/select methods, singleton access | Brain, LLM manager, reflection | INTEGRATED | Targeted tests PASS in prior integration run; runtime E2E NOT_PROVEN | Possible provider routing overlap | KEEP canonical and fail-closed |
| Hajeen model contract | `artifacts/base/qwen3-30b-a3b/`, `hajeen_model/` | Model | contract/metadata/manifest integration | Registry and Router | Artifact-level PROVEN; local runtime NOT_PROVEN | Verified-base tests PASS | Facade/provider overlap | KEEP; weights remain outside Git |
| Hajeen provider | `core/llm/providers/hajeen_provider.py` | Runtime/Model | provider adapter | LLM manager/Router | NOT_PROVEN | PARTIAL | Provider manager overlap | KEEP; prove GPU inference later |
| Runtime/Inference | `core/llm/`, `services/distributed_inference/`, inference modules | Runtime | provider and generation interfaces | Router, Brain | NOT_PROVEN for Qwen | PARTIAL | YES | KEEP; select one production runtime |
| Agents | `services/agents/`, `agent_frameworks/` | Cognitive/Agents | orchestrator/planner/agent interfaces | Brain and tools | PARTIAL | PARTIAL | YES | KEEP; define canonical orchestrator |
| Tools | tool and connector modules | Agents/Integrations | schemas, permissions, invocation | Brain/Agents | NOT_PROVEN | PARTIAL | Possible connector overlap | KEEP; enforce timeout/audit |
| Security/content policy | `security/` | Security | policy engine, PII/prompt/content checks | API, Brain, tools | PARTIAL | Security unit tests PASS | Multiple policy surfaces | KEEP; make enforcement mandatory |
| Workers/queues | `workers/`, task modules | Operations | task entrypoints/retry | ingestion, embeddings, notifications | CODE_EXISTS | PARTIAL | Multiple task abstractions | KEEP; prove idempotency and retry |
| Monitoring/audit | monitoring, metrics, audit modules | Operations/Governance | metrics/logging/tracing/audit | API, workers, model | CODE_EXISTS | PARTIAL | Multiple telemetry adapters | KEEP; define production telemetry contract |
| Training/evaluation | `hajeen_model/training/`, evaluation modules | Learning | datasets/checkpoints/evaluation | learning lifecycle/registry | CODE_EXISTS | PARTIAL | Legacy learning paths | KEEP isolated; training not started |
| Configuration | `configs/`, settings modules | Platform | settings/env/config loaders | all services | INTEGRATED | PARTIAL | Multiple config loaders | KEEP; separate dev/staging/prod |
| Infrastructure | `docker/`, `k8s/`, `helm/`, deployment files | Infrastructure | build/deploy manifests | CI/runtime | CODE_EXISTS | NOT_PROVEN | Multiple deployment surfaces | KEEP; validate deployment separately |
| Tests | `tests/` | QA | pytest suites | all components | PARTIAL | 1,864 collected before collection error | Legacy/duplicate suites possible | KEEP; repair collection gate |

## قرارات Phase 1

لا يُحذف أي تكرار في هذه المرحلة. كلمة `Duplicates = YES` تعني أن أكثر من مسار أو تعريف يحتاج إلى مقارنة، وليس أن الحذف مصرح به. القرار المعتمد الآن هو `KEEP` مع وضع المرشح في سجل التكرار، ثم اتخاذ قرار الدمج في مرحلة لاحقة بعد إثبات المستدعين.

## المراجع

[1]: https://github.com/abuafraa-glitch/AI-chat/tree/master/core/model "Model Registry source"
[2]: https://github.com/abuafraa-glitch/AI-chat/tree/master/brain "Brain and ModelRouter source"
[3]: https://github.com/abuafraa-glitch/AI-chat/tree/master/tests "Test suites"
