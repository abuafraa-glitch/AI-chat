# Selected Sources

| Source | Why selected |
|---|---|
| `brain/brain_v3.py` | Central runtime entry point and actual orchestration path |
| `core/model/model_registry.py` | Existing artifact approval and promotion authority |
| `core/model/model_router.py` | Existing model/provider selection authority |
| `core/inference/inference_engine.py` | Existing inference contract and backend boundary |
| `api/v1/ai/router.py` | Chat, RAG, and streaming API delegation |
| `api/v1/hajeen_model_router.py` | Model-facing API adapter and readiness claims to audit |
| `brain/memory/memory_fabric.py` | Canonical memory and trace/telemetry authority |
| `brain/learning/phase6_lifecycle.py` | Training/evaluation/artifact lifecycle authority |
| `brain/evolution/phase7_lifecycle.py` | Candidate/evaluation/approval/rollback integration boundary |
| `tests/integration/*` | Evidence of actual integration rather than imports |
| `/home/ubuntu/upload/pasted_content.txt` | User-provided Phase 8 requirements |
