# Runtime Call Graph

> هذا المخطط يميز بين المسار المعلن في التعليقات والمسار المثبت بإحالات الكود والاختبارات. `NOT_PROVEN` لا تعني أن الكود غير موجود؛ تعني أن دليل التنفيذ الكامل غير متوفر في Phase 1.

## المسار الرئيسي

```text
Client
  ↓
FastAPI / WebSocket
  ↓
Authentication / Dependencies
  ↓
AI Chat Router
  ↓
ChatService or direct BrainV3 route
  ↓
HajeenBrainV3.process() / stream()
  ├── Memory / context
  ├── RAG / retrieval
  ├── Tools / agents (capability-dependent)
  ↓
ModelRouter
  ├── consults ModelRegistry for model/artifact eligibility
  ↓
LLM manager / Hajeen provider / Runtime
  ↓
Verified Hajeen artifact (runtime not yet proven)
  ↓
Inference
  ↓
Post-processing / policy / audit
  ↓
JSON or SSE/WebSocket response
```

## انتقالات الدليل

| الانتقال | الدليل في الكود | الحالة |
|---|---|---|
| Client → FastAPI | routes in `api/main.py` and `api/v1/` | `PROVEN` at route definition |
| FastAPI → authentication/dependencies | API dependency and auth modules | `PARTIAL`; full auth E2E not proven |
| API → chat route | `api/v1/ai/chat.py`, `api/v1/ai/router.py`, WebSocket route | `PROVEN` at code integration |
| AI route → BrainV3 | imports/calls to `get_brain_v3`, `process`, `stream` | `PROVEN` at code/test level |
| ChatService → BrainV3 | `services/chat/chat_service.py` | `PROVEN` at code level; runtime E2E not proven |
| BrainV3 → Memory | Brain imports and cognitive pipeline references | `PARTIAL`; multiple memory implementations |
| BrainV3 → RAG | retrieval/cognitive references | `PARTIAL`; full source-grounded E2E not proven |
| BrainV3 → Tools/Agents | optional decision/agent paths | `PARTIAL`; capability-specific path not fully proven |
| BrainV3 → ModelRouter | decision/LLM paths and router references | `INTEGRATED`; runtime proof pending |
| ModelRouter → ModelRegistry | `brain/model_router.py` imports and registry object | `PROVEN` at code/integration level |
| ModelRegistry → verified artifact contract | `register_verified_base`, integrity assertions, contract/manifest paths | `PROVEN` for artifact contract tests |
| ModelRouter → Hajeen provider/runtime | provider adapter and LLM manager references | `INTEGRATED`; runtime not proven |
| Runtime → Qwen weights | requires external artifact and GPU environment | `NOT_PROVEN` |
| Inference → response | inference interfaces and API response wrappers | `PARTIAL`; real Qwen generation not proven |
| Response → client | JSON/SSE/WebSocket response code | `PROVEN` at route level; full E2E pending |

## Model path

```text
Hajeen Model Metadata / Contract
        ↓
ModelRegistry.register_verified_base()
        ↓
ModelRouter integrity and eligibility checks
        ↓
Hajeen provider / Runtime
        ↓
Qwen3-30B-A3B artifact at pinned target commit
        ↓
Inference
```

The registry is a source of model/artifact authority consulted by the router. In normal execution, BrainV3 requests routing; it is not correct to model the runtime as `Registry → Router → Brain`. The accurate control flow is `BrainV3 → Router`, with `Router → Registry` as a validation and selection dependency.

## Hajeen evidence separation

| Layer | Current evidence | Status |
|---|---|---|
| Artifact Verification | source/target metadata, commit pin, manifest contract, sharded artifact tests | `PROVEN` for recorded artifact contract; external weights not in Git |
| Runtime Verification | no successful GPU load in this environment | `NOT_PROVEN` |
| Inference Verification | no successful Qwen3-30B-A3B generation in target runtime | `NOT_PROVEN` |
| Training Verification | training not started by requirement | `N/A / NOT_STARTED` |

## References

[1]: https://github.com/abuafraa-glitch/AI-chat/blob/master/api/v1/ai/chat.py "AI chat routes"
[2]: https://github.com/abuafraa-glitch/AI-chat/blob/master/services/chat/chat_service.py "Chat service"
[3]: https://github.com/abuafraa-glitch/AI-chat/blob/master/brain/brain_v3.py "BrainV3"
[4]: https://github.com/abuafraa-glitch/AI-chat/blob/master/brain/model_router.py "ModelRouter"
[5]: https://github.com/abuafraa-glitch/AI-chat/blob/master/core/model/model_registry.py "ModelRegistry"
