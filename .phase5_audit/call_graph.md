# Phase 5 Actual Call Graph and Authority Matrix

## Canonical production graph at baseline

```text
HTTP API
  -> request.app.state.brain
  -> HajeenBrainV3.process() / HajeenBrainV3.stream()
  -> MemoryFabric.get_conversation()
  -> PolicyEngine.evaluate()
  -> IntentAnalyzer.analyze()
  -> GoalManager.analyze()
  -> ContextAnalyzer.analyze()
  -> ReasoningEngine.reason()
  -> DecisionEngine.decide()
  -> RAGPipeline.run() [when use_rag]
  -> UnifiedPromptBuilder.build()
  -> ModelRouter.route()/stream()
  -> MemoryFabric.conversation.add_message(assistant)
  -> BrainResponse / LLMStreamChunk
  -> HTTP API
```

## Agent graph at baseline

```text
No verified API/BrainV3 caller
  -> AgentOrchestrator.run(goal)
  -> PlannerAgent.run()
  -> RetrievalAgent.run()
  -> ExecutionAgent.run()
  -> BaseAgent-local context/memory/tools
  -> injected llm / rag_service / memory_service
```

The second graph is a parallel runtime and is not integrated with the first graph.

## Required Phase 5 graph

```text
API
  -> BrainV3
  -> central PolicyEngine + deterministic agent-selection decision
  -> AgentOrchestrator
      -> typed Task/Plan lifecycle
      -> ToolRegistry
      -> Policy/permission check
      -> ToolExecutor
      -> Observation
      -> transient AgentExecutionContext
      -> MemoryFabric for persistent conversation/task observations
      -> BrainV3 reasoning/model request
      -> ModelRouter
      -> native provider stream or verified batch result
  -> BrainV3 trace and final response
  -> API
```

## Authority matrix

| Concern | Canonical authority | Baseline duplicate/bypass | Phase 5 action |
|---|---|---|---|
| Request entry | `HajeenBrainV3` | API direct calls only, which is correct | Add agent delegation inside BrainV3 |
| Agent selection | `DecisionEngine` plus Brain trace | No agent decision in runtime | Add deterministic, traceable decision |
| Orchestration | None integrated; isolated `AgentOrchestrator` | `AgentService`, autonomous stack, runtime executors | Unify central orchestrator; preserve legacy adapters/isolation |
| Planning | `PlannerAgent` isolated | `RecursivePlanner`, `AgentService` heuristic loop | Typed canonical plan; legacy surfaces not authorities |
| Tool registry | None canonical | `AgentService.ToolRegistry`, BaseAgent `_tools` | One typed registry |
| Tool execution | None canonical | direct callable invocation, autonomous dispatch | One permission-aware executor |
| Security | `PolicyEngine` in BrainV3 | Agents do not invoke policy | Reuse policy authority for every tool |
| Conversation memory | `MemoryFabric` | `AgentMemory`, `SharedMemoryBus`, memory agent | Use MemoryFabric; transient execution state stays in context |
| Prompt construction | `UnifiedPromptBuilder` | direct prompt strings/builders in agents | Route reasoning/planning through central builder/adapter |
| Retrieval | `RAGPipeline` | RetrievalAgent injected service/direct retrieval | Adapter to canonical pipeline |
| Model selection/execution | `ModelRouter` | injected `llm`, direct `agenerate`/`generate` | Inject ModelRouter capability, no agent model access |
| Streaming | `LLMStreamChunk` via BrainV3 | no canonical agent stream | Reuse BrainV3/ModelRouter stream |
| Trace | `BrainV3.ExecutionTrace` | `brain/execution_trace.py`, `AgentTrace` | Add agent events to BrainV3 trace; no second authority |

## Runtime reachability conclusion

The baseline grep and source inspection found no production references from `api`, `brain`, or the canonical startup path to `AgentOrchestrator` or `AgentService`. Imports inside `services/agents` prove package existence only and do not prove integration. Therefore Phase 5 must add one explicit BrainV3-to-orchestrator edge and tests must assert that edge.

## Out-of-scope components

The following are not activated by the canonical path and are not promoted to authorities during Phase 5: self-evolution, dream/learning components, Kubernetes/deployment surfaces, the dynamic workflow executor, framework examples, autonomous recursive planning, multi-agent shared memory, and distributed workers. They remain untouched unless a minimal compatibility adapter is proven necessary.
