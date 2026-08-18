# Phase 7 Call Graph

## Verified canonical path

```text
BrainV3.process()
  -> real runtime trace / response quality or failure evidence
  -> EvolutionLifecycle.observe(..., hypothesis=explicit, evidence_refs=...)
  -> EvolutionLifecycle.run_experiment()
  -> injected isolated executor
  -> EvolutionLifecycle.reflect_and_evaluate()
  -> injected evidence reflector
  -> Phase 6 evaluator adapter (when configured)
  -> EvaluationPipelineLifecycle
  -> benchmark validation + infer_and_measure + metrics/thresholds
  -> EvolutionLifecycle.approve()
  -> PolicyEngine/policy callback
  -> ModelRegistry.mark_evaluated() + ModelRegistry.approve() when registry is injected
  -> EvolutionLifecycle version record
  -> injected staging/deployer
  -> injected rollbacker
```

## Memory path

```text
EvolutionLifecycle._event / _memory
  -> MemoryFabric-compatible record_episode / memorize_semantically adapter
  -> evolution telemetry namespace/metadata
```

The lifecycle does not create `SelfEvolutionMemory`, `EvolutionMemoryFabric`, or conversation assistant messages.

## Legacy paths intentionally blocked

```text
legacy Celery evolution_proposal_task
  -> rejected: legacy_evolution_path_disabled

legacy Celery evolution_evaluation_task
  -> rejected: legacy_evolution_path_disabled

brain.evolution.self_evolution.SelfEvolution
  -> analyze_and_propose* -> EvolutionLifecycleError
  -> evaluate_and_implement* -> EvolutionLifecycleError
  -> _implement_change -> EvolutionLifecycleError
```

## Unverified/orphan paths

```text
DreamEngine -> no verified canonical caller
CuriosityEngine -> no verified canonical caller
services.self_evolution.* -> no verified BrainV3 caller
AutonomousImprovement -> no verified deployment caller
older continuous_learning.py -> separate legacy deployment behavior; not used by Phase 7
```

## Important negative evidence

Importing or instantiating the orphan engines does not prove runtime integration. Their callers were not found in the central BrainV3 path, therefore they remain blocked and documented rather than activated.
