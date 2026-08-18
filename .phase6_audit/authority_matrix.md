# Phase 6 Authority Matrix

| Component | Current role | Canonical owner | Bypass / risk | Required treatment |
|---|---|---|---|---|
| `StorageManager` | raw/bronze/silver/gold and SQLite catalog | Storage authority | Direct filesystem helpers can bypass metadata | Keep storage writes behind lifecycle adapters |
| `DataPreparationPipeline` | synchronous validation, language filter, score, dedup | Dataset preparation stage | Prints only; no run manifest | Add typed result/manifest wrapper |
| `DatasetCleaner` | alternate cleaning/language helper | Dataset preparation stage | Language exceptions keep records silently | Replace silent fallback with explicit unknown policy |
| `DatasetVersioner` | checksum/filesystem version helper | Dataset version authority | No status gate or complete metadata serialization | Extend backward-compatibly |
| `ContinuousLearningPipeline` | broad offline lifecycle | Lifecycle coordinator candidate | `approve_pending` state is global; deployment semantics weak | Refactor/use as coordinator; never claim deferred work completed |
| `TrainingPipeline` | torch/Hajeen mechanics | Training executor | No run/artifact record | Invoke only under lifecycle gate |
| `core.training_engine.trainer` | HF generic mechanics | Training executor | No lifecycle integration | Keep lower-level |
| `core.training_engine.evaluator` | metric helpers | Evaluation executor | No evaluation identity/gate | Wrap with persisted evaluation run |
| `ModelRegistry` | in-process runtime configs | Runtime model metadata | Name suggests full registry but lacks artifacts/approval | Extend without breaking `/models` |
| `LineageTracker` | SQL lineage rows | Lineage persistence primitive | No workflow/status semantics | Call from lifecycle coordinator |
| `ModelRouter` | provider selection/inference | Runtime routing authority | Any training code registering directly is unsafe | Permit only approved runtime artifacts/configs |
| `BrainV3` | request/runtime orchestration | Inference authority | Training logic in request path would violate separation | Keep Phase 6 out of request execution |
| `MemoryFabric` | conversation/observations SSOT | Memory authority | Dataset pipeline must not write assistant conversation messages | Record lifecycle observations only through explicit API |

## Non-negotiable security rules

- Remote HuggingFace loading is never implicit in production training/evaluation.
- A missing local checkpoint yields `deferred`/`blocked`, never a successful run.
- A failed validator or policy engine yields a closed gate.
- Unapproved model artifacts cannot be routed by `ModelRouter`.
- Dataset content is treated as data, not executable instructions.
