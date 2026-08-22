# Phase 4 — Runtime Context Propagation

## Context contract

```text
request_id
user_id
tenant_id
conversation_id
model_id
```

## Evidence matrix

| Context field | API/service | Brain/Router | Worker | Status |
|---|---|---|---|---|
| `request_id` | Present in streaming/service concepts | Present in routing/audit concepts | Partial | PARTIAL |
| `user_id` | Present in auth vocabulary | Not proven through every Brain call | Not proven end-to-end | NOT_PROVEN |
| `tenant_id` | Present in security/service vocabulary | Not proven through every Router call | Partial references | PARTIAL |
| `conversation_id` | Present in ChatService/session path | Partial in cognitive path | Not proven for every task | PARTIAL |
| `model_id` | Present in model contracts | Router/Registry use it | Worker model loading uses model name | INTEGRATED / PARTIAL |

## Worker finding

`workers/distributed/gpu_worker.py` loads through `core.model.loader.ModelLoader` and executes `model.generate` after device reservation. This is classified as `WORKER_RUNTIME_EXCEPTION`, not an automatic bypass. The missing proof is the complete request-to-worker context and authorization audit trail.

## Status

`PARTIAL`. A Phase 5 or specialized worker test must assert that a task cannot lose or replace tenant/user identity while preserving model execution.
