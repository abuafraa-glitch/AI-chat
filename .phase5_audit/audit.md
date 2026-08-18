# Phase 5 Audit — Agents, Tools, Orchestration

## Baseline

- Repository: `abuafraa-glitch/AI-chat`
- Branch: `master`
- Baseline commit: `84333003b41131dbf4546aff6e0d8e4c43fd69d3`
- Main: not inspected for modification and must remain untouched.
- Audit mode: read-only source inspection before runtime reconstruction.

## Executive finding

The canonical production entrypoint is currently `API -> HajeenBrainV3 -> DecisionEngine -> UnifiedPromptBuilder/RAGPipeline -> ModelRouter -> MemoryFabric`. The existing Agent implementations are not wired into API or BrainV3. They form a parallel, mostly legacy/experimental pipeline and therefore the acceptance criterion “Agent runtime is integrated” is not currently satisfied.

## Component classification

| Component | Location | Status | Runtime reachability | Main issue |
|---|---|---|---|---|
| BrainV3 | `brain/brain_v3.py` | Production | API reaches it directly | Correct central authority; no AgentOrchestrator call yet |
| ModelRouter | `brain/model_router.py` | Production | BrainV3 | Must remain sole model authority |
| MemoryFabric | `brain/memory/memory_fabric.py` | Production | BrainV3 | AgentMemory in `services/agent_service.py` is a competing store |
| UnifiedPromptBuilder | `brain/prompts/unified_prompt_builder.py` | Production | BrainV3/RAG | Existing agents build prompts independently |
| RAGPipeline | `services/rag/rag_pipeline.py` | Production | BrainV3 | RetrievalAgent bypasses it |
| DecisionEngine | `brain/decision_engine.py` | Production | BrainV3 | Correct integration point for deterministic agent selection |
| AgentOrchestrator | `services/agents/agent_orchestrator.py` | Production-looking but isolated | No API/Brain caller found | Owns pipeline but not central authorities; no cancellation/timeout/trace authority |
| PlannerAgent | `services/agents/planner_agent.py` | Partially implemented | Only via isolated orchestrator | Returns `List[str]`, uses direct LLM and heuristic fallback |
| BaseAgent | `services/agents/base_agent.py` | Shared legacy contract | Only agent package | Provides agent-local tool dictionary and catches all exceptions |
| ExecutionAgent | `services/agents/execution_agent.py` | Partially implemented | Default orchestrator pipeline | Calls agent-local tools/direct LLM; has non-fail-closed completion behavior |
| RetrievalAgent | `services/agents/retrieval_agent.py` | Partially implemented | Default orchestrator pipeline | Calls injected RAG service directly, not canonical RAGPipeline |
| ToolAgent | `services/agents/tool_agent.py` | Isolated | No central runtime caller found | Local tool selection/execution and direct LLM |
| AgentService | `services/agent_service.py` | Legacy production-looking | No API/Brain caller found | Duplicate ToolRegistry, AgentMemory, AgentTrace; direct LLM; `eval` calculator; fallback thought generation |
| Autonomous stack | `services/agents/autonomous/*` | Experimental/isolated | No API/Brain caller found | Direct LLM, local executor, retries/fallback acknowledgements |
| Multi-agent stack | `services/agents/multi_agent/*` | Experimental/isolated | No API/Brain caller found | `SharedMemoryBus` is a competing transient/state surface |
| orchestration/runtime | `orchestration/runtime/*` | Experimental/isolated | No live caller found | Duplicate runtime surfaces; dynamic executor contains simulated workflow behavior |
| brain/execution_trace.py | `brain/execution_trace.py` | Parallel trace surface | No live caller found in audited production path | BrainV3 has its own `ExecutionTrace`; must not create a second authority |

## Verified call graph before Phase 5

```text
API /chat or /chat/stream
  -> request.app.state.brain
  -> HajeenBrainV3.process() / stream()
  -> MemoryFabric conversation context
  -> PolicyEngine
  -> IntentAnalyzer
  -> GoalManager
  -> ContextAnalyzer
  -> ReasoningEngine
  -> DecisionEngine
  -> optional RAGPipeline
  -> UnifiedPromptBuilder
  -> ModelRouter.route()/stream()
  -> MemoryFabric assistant commit
  -> API response/native stream
```

There is no verified production edge from API or BrainV3 to `AgentOrchestrator`, `AgentService`, `PlannerAgent`, or `ToolRegistry`.

## Existing isolated agent graph

```text
caller (not API/BrainV3)
  -> AgentOrchestrator.run()
  -> PlannerAgent
  -> RetrievalAgent
  -> ExecutionAgent
  -> BaseAgent-local state/tools
  -> direct injected llm / rag_service / memory_service
```

This graph is not acceptable as the canonical Phase 5 graph because it bypasses BrainV3, ModelRouter, UnifiedPromptBuilder, RAGPipeline, MemoryFabric, and Security/Policy.

## Confirmed bypasses and fail-open behavior

1. `services/agents/planner_agent.py` invokes `self._llm.agenerate()` directly and falls back to heuristic plan output.
2. `services/agents/execution_agent.py` invokes the injected LLM directly and uses agent-local tool functions.
3. `services/agents/retrieval_agent.py` calls an injected RAG service directly rather than `RAGPipeline`.
4. `services/agents/base_agent.py` stores arbitrary functions in `_tools` and calls them through `_call_tool()` without registry, permission, policy, input/output schema, timeout, or audit checks.
5. `services/agent_service.py` defines a second `ToolRegistry`, a second `AgentMemory`, and a second execution loop. It calls an injected LLM directly and uses restricted-character `eval()` for calculation; this remains unsuitable as a production authority.
6. Autonomous task execution can route to local functions, agent internals, or direct LLM and contains acknowledgement fallback behavior when no executor exists.
7. Existing `AgentOrchestrator.run()` has no unified cancellation, execution timeout, permission stage, retry classification, idempotency, or canonical BrainV3 trace integration.
8. Agent selection is not currently represented as a central deterministic decision in BrainV3.

## Required unification decision

The Phase 5 implementation must use `BrainV3` as the entry/control point and make one canonical `AgentOrchestrator` adapter/runtime consume injected central authorities. Legacy `AgentService`, local agent tools, autonomous execution, and duplicate memory/trace surfaces must not become competing authorities. They should either be adapted, deprecated, or left isolated with explicit non-runtime classification and tests preventing accidental use.

## Initial file scope

Expected production changes are limited to:

- `brain/brain_v3.py` — deterministic agent selection and central orchestration delegation.
- `services/agents/agent_orchestrator.py` — canonical orchestration lifecycle and authority injection.
- `services/agents/base_agent.py` — typed execution context/state/trace compatibility.
- `services/agents/planner_agent.py` — typed executable plan contract through central model/prompt authorities.
- `services/agents/execution_agent.py` and/or a canonical tool module — only as required for ToolRegistry/Executor integration.
- `services/agents/retrieval_agent.py` — adapter to canonical RAGPipeline, if retained.
- `brain/decision_engine.py` or policy contract — only if required to expose agent-selection decision without unrelated refactoring.
- `tests/integration/test_phase5_agents_tools.py` — acceptance and failure tests.
- `reports/checkpoints/*` or equivalent Phase 5 report artifacts.

No Phase 6 learning/data/evaluation work, self-evolution, training, Kubernetes, deployment, billing, or broad legacy cleanup is in scope.

## Audit verdict

Audit complete. The repository has agent-related code, but the Agent runtime is **not integrated** into the canonical production path. Phase 5 implementation may now begin, starting with typed contracts and a central adapter while preserving Phase 1–4 authorities.
