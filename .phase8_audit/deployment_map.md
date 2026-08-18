# Deployment and Readiness Map

Phase 8 does not perform external/cloud deployment. It prepares a controlled runtime integration only.

Liveness means the process is alive. Readiness means the approved artifact is present and integral, registry approval is valid, tokenizer and architecture metadata match, model load completed, device/backend is available, and inference capability is available.

Required status path:

`process alive → liveness` and independently `artifact/registry/tokenizer/load/runtime checks → readiness`.

If any readiness condition fails, `/ready` must report not ready and API inference must return an explicit model/runtime error without an assistant message or fake stream chunks.

API routers remain adapters and must not load models. BrainV3 remains the central entry point. No external deployment, API purchase, key creation, or force push is part of this phase.
