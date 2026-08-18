# Phase 8 Authority Matrix

| Decision | Canonical authority | Runtime responsibility | Forbidden bypass |
|---|---|---|---|
| Model/provider selection | `ModelRouter` | Request eligible runtime only | `force_model` direct selection, provider selection in API/runtime |
| Artifact state/approval/promotion | `ModelRegistry` | Query eligibility and approval | Local registry or direct promotion |
| Artifact integrity | shared `ArtifactValidation` / Phase 6 contract | Validate before load | Runtime-specific duplicate validator |
| Central execution | `BrainV3` | Orchestrate policy, context, agents, RAG, memory, model call | API router direct inference |
| Prompt construction | `UnifiedPromptBuilder` | Consume built prompt | Runtime-specific prompt builder |
| Retrieval | canonical `RAGPipeline` | Receive prepared context | Vector store inside model runtime |
| Agents/tools | `AgentOrchestrator` and planner/tool authorities | Generate only through central path | Direct model call from tools/agents |
| Memory | `MemoryFabric` | Store traces/metadata through central namespace | ModelMemory/HajeenMemory/InferenceMemory authority |
| Candidate evolution | `EvolutionLifecycle` + Phase 6 + policy + registry | Runtime consumes approved result | Direct replacement by evolution |
| Readiness | runtime state plus registry/validation | Report actual readiness | `ready=true` because process exists |
