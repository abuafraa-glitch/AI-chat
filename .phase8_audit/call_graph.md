# Phase 8 Call Graph

## Canonical request path

`api/v1/ai/router.py` → `HajeenBrainV3.process()` / `stream()` → `ModelRouter` → eligible provider/runtime → native result/stream → BrainV3 response/stream adapter.

## Model-facing facade

`api/v1/hajeen_model_router.py` → `HajeenBrainV3`; this facade must remain an API adapter only. It must not load a checkpoint, select a provider, or fabricate readiness.

## Retrieval path

`BrainV3` → injected `RAGPipeline` → context → `UnifiedPromptBuilder` → `ModelRouter` → runtime. Runtime must not call retrieval or construct a vector store.

## Agent path

`BrainV3` → decision/planner → `AgentOrchestrator` → `ToolExecutor` → final generation through the central router. No `AgentModelRouter` is permitted.

## Artifact path required by Phase 8

`Phase 6 training/evaluation artifact` → `ModelRegistry` approval/eligibility → shared artifact validation → runtime discovery/validation/loading → readiness → `ModelRouter` selection → inference.

## Evolution path

`EvolutionLifecycle` → Phase 6 evaluation → policy approval → `ModelRegistry` → approved artifact/runtime. Evolution never replaces a live model directly.

## Missing proof at audit time

The repository did not prove a real approved Hajeen checkpoint and tokenizer loaded into a production runtime. Phase 8 must therefore implement an explicit not-ready state and fail-closed inference, with tests using doubles only under tests.
