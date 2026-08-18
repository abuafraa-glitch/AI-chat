# Authority Matrix

| Capability | Canonical authority | Phase 7 usage | Duplicate/legacy risk | Decision |
|---|---|---|---|---|
| Runtime orchestration | `brain/brain_v3.py` / `HajeenBrainV3` | Emits real runtime evidence and receives optional lifecycle injection | Legacy loops may bypass BrainV3 | Keep BrainV3 central |
| Model routing | ModelRouter | Candidate evaluation must use injected runtime/model interfaces | Direct model calls from legacy components | No new router |
| Memory | MemoryFabric | Stores evolution telemetry through compatible methods | Local evolution memories | No new memory authority |
| Prompt construction | UnifiedPromptBuilder | Existing BrainV3 path remains unchanged | Reflection/legacy engines may construct their own prompts | No Phase 7 replacement |
| Retrieval | RAGPipeline | Existing BrainV3 path remains unchanged | Legacy retrieval experimentation can bypass RAG | Candidate only through isolated executor |
| Agents | AgentOrchestrator | Existing BrainV3 path remains unchanged | Legacy agent loops | No new orchestration |
| Tools | ToolRegistry / ToolExecutor | Any future capability must be injected through policy-controlled interfaces | Arbitrary shell/code/network in experiments | Not exposed by Phase 7 |
| Security | PolicyEngine | Approval/deployment policy callback; registry gates | Local `if better` decisions | Approval remains explicit |
| Data lifecycle | Data Engine | Existing Phase 6 data authority | Continuous-learning legacy path | No second data path |
| Training/evaluation | LearningLifecycleCoordinator / Phase 6 evaluator | `make_phase6_evaluator` delegates to Phase 6 | Local evaluation stubs | Phase 6 remains canonical |
| Artifact integrity | ArtifactValidation / ModelRegistry | ModelRegistry approval requires evaluated artifact and integrity checks | Evolution-local registry | No EvolutionModelRegistry |
| Model/artifact lifecycle | ModelRegistry | `mark_evaluated` then `approve` when injected | Legacy deployment registries | ModelRegistry remains canonical |
| Evolution lifecycle | `brain/evolution/phase7_lifecycle.py` | Single authority for observation through rollback | Reflection/self-evolution/engine duplicates | Canonical Phase 7 lifecycle |
| Deployment | Injected deployer plus policy gate | Explicit, idempotent, versioned deployment | Automatic legacy deployment | No automatic production mutation |
| Rollback | Injected rollbacker and ModelRegistry where applicable | Explicit only after deployed state | Local rollback implementations | Reuse central rollback authority where available |
