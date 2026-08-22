# Phase 4 — Direct Model Calls Audit

## قاعدة التصنيف

وجود `model.generate` داخل مسار تنفيذ GPU لا يُعد تجاوزاً تلقائياً؛ يجب معرفة هل يقع خلف واجهة Runtime/Worker رسمية أم يتجاوز ModelRouter.

| Location / pattern | Classification | Status | Finding |
|---|---|---|---|
| `brain/model_router.py` | Canonical routing boundary | INTEGRATED | Router is the intended model-selection boundary |
| `core/model/model_registry.py` | Registry boundary | INTEGRATED | Stores model identity/status and verification contract |
| `services/chat/chat_service.py` | Service → inference/Brain | INTEGRATED | Uses service abstractions and streaming paths |
| `services/inference_service.py` | Service → LLM abstraction | INTEGRATED | Calls configured LLM stream interface |
| `workers/distributed/gpu_worker.py::_generate` | WORKER_RUNTIME_EXCEPTION | CODE_EXISTS | Calls `model.generate` after worker loading/reservation; valid only if worker admission is guarded |
| `workers/distributed/gpu_worker.py::_load_model` | WORKER_RUNTIME_EXCEPTION | PARTIAL | Loads through `core.model.loader.ModelLoader`; tenant/model/request context proof is incomplete |
| `hajeen_model` runtime | Canonical provider candidate | PARTIAL | Fail-closed contracts exist; real Qwen runtime unavailable |
| direct provider/LLM calls found by static grep | UNKNOWN until call-site proof | UNKNOWN | Static occurrence is not sufficient to declare bypass |

## Required follow-up

1. Build a call-site inventory with caller, callee, model identifier source, authorization context, and environment.
2. Require workers to receive `request_id`, `tenant_id`, `user_id`, `conversation_id`, and `model_id` where applicable.
3. Reject production Test Provider configuration.
4. Keep GPU `model.generate` as a documented `WORKER_RUNTIME_EXCEPTION` only when admission and audit are enforced.

## Decision

No deletion or relocation is authorized in Phase 4. The audit result is `PARTIAL` with `UNKNOWN` call sites requiring targeted tracing.
