# Phase 7 Audit

## Scope

This audit inspects the actual Python implementation under `brain/`, `services/`, `workers/`, `core/`, and `tests/`. File existence, imports, and isolated unit tests are not treated as integration evidence. Integration is marked **verified** only where a runtime call chain or an integration test proves it.

## Baseline

The repository is on `master`. The previous known checkpoint is `40551fb`; the current repository already contains Phase 7 implementation commits `4c92b08` and `93b3441`.

## Findings by component

| Component | Actual implementation | Caller/runtime path | Persistence/state | Stub or unsafe behavior | Status | Action |
|---|---|---|---|---|---|---|
| `brain/cognitive_layer/curiosity_engine.py` | `CuriosityEngine`, gap/query generation and a query execution method | No verified BrainV3 production caller found by repository search | In-memory dictionaries for gaps and queries | Execution contains local knowledge-gap behavior and is not connected to canonical Phase 7 evidence contracts | **ORPHAN / BLOCKED** | Preserve as research candidate source only; adapt through observation/hypothesis gate, never deployment |
| `brain/cognitive_layer/hypothesis_engine.py` | Hypothesis data/generation helpers | No verified central runtime caller | Local in-memory state | Legacy proposal semantics are not the Phase 7 typed lifecycle | **ORPHAN / BLOCKED** | Do not use as authority; route future use through `EvolutionLifecycle.observe` |
| `brain/cognitive_layer/experiment_engine.py` | Legacy `ExperimentEngine` | No verified production caller | Local experiment state | Previous simulated execution path was hardened to fail closed | **COMPATIBILITY ONLY** | Keep API if required, reject execution outside canonical lifecycle |
| `brain/cognitive_layer/dream_engine.py` | `DreamEngine` schedules and tracks dreams | No verified production scheduler/caller | In-memory dream registry | No bounded canonical Phase 7 integration; no proven deployment prohibition through central policy | **ORPHAN / BLOCKED** | Do not activate automatically; future adapter may emit observations/hypotheses only |
| `brain/reflection/self_reflection.py` | Reflection report generation | Used by legacy reflection task and reflection components | Report/storage behavior is local to reflection module | A generated report alone is not an evidence-backed evaluation | **PARTIAL** | Treat runtime traces/metrics as evidence; do not let report directly create deployment |
| `brain/reflection/self_evolution.py` | Older reflection-oriented self-evolution implementation | Historically reachable from legacy evolution paths | Local proposal/state behavior | Competes with canonical Phase 7 authority | **BYPASS RISK** | Keep outside canonical runtime; legacy facade rejects unsafe operations |
| `brain/evolution/self_evolution.py` | Compatibility facade with `EvolutionProposal` serialization | Legacy callers and Celery names | In-memory pending list only | All proposal/evaluation/mutation operations fail closed with `EvolutionLifecycleError` | **VERIFIED SAFE** | Retain only for backward compatibility |
| `brain/improvement/autonomous_improvement.py` | Weekly reports and suggestions | No verified BrainV3 production caller | Local storage reports/suggestions | Suggestion generation is not an approval/evaluation lifecycle | **ORPHAN / BLOCKED** | Reports may inform evidence review only; no direct implementation |
| `brain/learning/continuous_learning.py` | Older collection/training/evaluation/deployment pipeline | Legacy learning callers | Local pipeline/run files and deployment registry | Contains a separate deployment path and therefore can bypass Phase 6 if invoked | **BYPASS RISK** | Do not use as Phase 7 authority; Phase 6 coordinator remains canonical |
| `services/self_evolution/continuous_learning_loop.py` | Loop around inference, reflection, memory, curiosity | No verified canonical BrainV3 call chain | Depends on injected local collaborators | Can imply runtime self-learning unless bounded and routed through Phase 6 | **ORPHAN / BLOCKED** | Keep unactivated; document as requiring adapter |
| `services/self_evolution/curiosity_engine.py` | Service-level curiosity implementation | No verified canonical caller | Service-local state | Duplicate curiosity authority | **DUPLICATE / BLOCKED** | Do not create another evolution path |
| `services/self_evolution/self_reflection_engine.py` | Service reflection engine | No verified canonical caller | Service-local state | Duplicate reflection authority | **DUPLICATE / BLOCKED** | Do not activate outside BrainV3 evidence path |
| `brain/evolution/phase7_lifecycle.py` | Typed observation, hypothesis, experiment, evaluation, approval, version, deployment, rollback lifecycle | Optional BrainV3 injection and direct integration tests | In-memory records plus MemoryFabric telemetry adapter | Deployment still requires injected deployer, policy, and rollbacker; no automatic production mutation | **CANONICAL / VERIFIED** | Single Phase 7 authority |

## Confirmed safety posture

No Phase 7 path is allowed to mutate production merely because an LLM or legacy component generated text. The canonical lifecycle requires evidence, an experiment result, evaluation, policy approval, versioning, and explicit deployment dependencies. Missing authorities fail closed.

## Out-of-scope findings

The audit found legacy components that need future adapters, but this task does not start Phase 8, build Hajeen Model, perform broad refactoring, or redesign unrelated authorities. These findings are documented rather than activated.
