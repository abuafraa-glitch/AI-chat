"""Canonical Phase 5 agent orchestration runtime."""
from __future__ import annotations

import asyncio
import inspect
import logging
import time
from typing import Any, Awaitable, Callable, Dict, List, Optional

from brain.memory.memory_fabric import MemoryFabric
from brain.policy.policy_engine import PolicyEngine

from .contracts import (
    AgentExecutionContext,
    AgentRunResult,
    AgentTraceEvent,
    ExecutionPlan,
    Observation,
    PlanStep,
    TaskStatus,
    ToolCall,
)
from .tool_runtime import ToolExecutor, ToolRegistry

logger = logging.getLogger(__name__)


PlanProvider = Callable[[AgentExecutionContext], Awaitable[ExecutionPlan] | ExecutionPlan]
Reasoner = Callable[[AgentExecutionContext, PlanStep, List[Observation]], Awaitable[Any] | Any]


class AgentOrchestrator:
    """Single orchestration authority using central platform services.

    The orchestrator owns only transient task lifecycle. Model selection, prompt
    construction, retrieval, policy, and persistent memory remain injected
    authorities owned by BrainV3/platform services.
    """

    def __init__(
        self,
        *,
        model_router: Any,
        memory_fabric: MemoryFabric,
        prompt_builder: Any,
        policy_engine: PolicyEngine,
        rag_pipeline: Optional[Any] = None,
        tool_registry: Optional[ToolRegistry] = None,
        tool_executor: Optional[ToolExecutor] = None,
        plan_provider: Optional[PlanProvider] = None,
        reasoner: Optional[Reasoner] = None,
        max_steps: int = 10,
        execution_timeout_seconds: float = 120.0,
    ) -> None:
        if max_steps <= 0 or execution_timeout_seconds <= 0:
            raise ValueError("Agent limits must be positive")
        self.model_router = model_router
        self.memory_fabric = memory_fabric
        self.prompt_builder = prompt_builder
        self.policy_engine = policy_engine
        self.rag_pipeline = rag_pipeline
        self.tool_registry = tool_registry or ToolRegistry()
        self.tool_executor = tool_executor or ToolExecutor(self.tool_registry, policy_engine)
        self.plan_provider = plan_provider
        self.reasoner = reasoner
        self.max_steps = max_steps
        self.execution_timeout_seconds = execution_timeout_seconds
        self._active: Dict[str, asyncio.Task[Any]] = {}
        self._traces: Dict[str, List[AgentTraceEvent]] = {}

    async def run(
        self,
        goal: str,
        *,
        session_id: str,
        user_id: Optional[str] = None,
        plan: Optional[ExecutionPlan] = None,
        max_steps: Optional[int] = None,
    ) -> AgentRunResult:
        context = AgentExecutionContext(
            goal=goal,
            session_id=session_id,
            max_steps=max_steps or self.max_steps,
            execution_timeout_seconds=self.execution_timeout_seconds,
            status=TaskStatus.RUNNING,
        )
        events: List[AgentTraceEvent] = []
        self._traces[context.task_id] = events
        task = asyncio.current_task()
        if task is not None:
            self._active[context.task_id] = task
        self._record(events, context, "task_started", {"goal": goal})
        try:
            result = await asyncio.wait_for(
                self._execute(context, events, session_id=session_id, user_id=user_id, plan=plan),
                timeout=context.execution_timeout_seconds,
            )
            return result
        except asyncio.CancelledError:
            context.status = TaskStatus.CANCELLED
            self._record(events, context, "task_cancelled")
            raise
        except asyncio.TimeoutError:
            context.status = TaskStatus.FAILED
            self._record(events, context, "task_timeout", {"timeout_seconds": context.execution_timeout_seconds})
            return AgentRunResult(False, None, context, events, "Agent execution timeout")
        except Exception as exc:
            context.status = TaskStatus.FAILED
            self._record(events, context, "task_failed", {"error": str(exc)})
            return AgentRunResult(False, None, context, events, str(exc))
        finally:
            # Agent observations belong to the central AgentMemory authority.
            # This is task telemetry, not an assistant conversation message.
            try:
                self.memory_fabric.record_agent_experience(
                    "agent_orchestrator",
                    context.goal,
                    context.status.value,
                    context.status == TaskStatus.COMPLETED,
                )
                self._record(events, context, "memory_observation_recorded", {
                    "memory": "MemoryFabric",
                    "agent_id": "agent_orchestrator",
                    "success": context.status == TaskStatus.COMPLETED,
                })
            except Exception as exc:
                # Memory telemetry must never turn a completed task into a fake
                # success or bypass the central runtime; retain the task result.
                logger.warning("Agent memory observation failed: %s", exc)
            self._active.pop(context.task_id, None)

    async def _execute(
        self,
        context: AgentExecutionContext,
        events: List[AgentTraceEvent],
        *,
        session_id: str,
        user_id: Optional[str],
        plan: Optional[ExecutionPlan],
    ) -> AgentRunResult:
        if plan is None:
            if self.plan_provider is None:
                raise RuntimeError("No canonical planner configured")
            generated = self.plan_provider(context)
            plan = await generated if inspect.isawaitable(generated) else generated
        if not isinstance(plan, ExecutionPlan) or not plan.steps:
            raise RuntimeError("Planner returned a malformed executable plan")
        if len(plan.steps) > context.max_steps:
            raise RuntimeError("Plan exceeds max_steps")
        context.plan = plan
        self._record(events, context, "plan_created", {"plan_id": plan.plan_id, "steps": len(plan.steps)})

        final_output: Any = None
        for step in plan.steps:
            if context.steps_completed >= context.max_steps:
                raise RuntimeError("Maximum agent steps exceeded")
            if any(
                next((candidate.status for candidate in plan.steps if candidate.step_id == dep), TaskStatus.FAILED)
                != TaskStatus.COMPLETED
                for dep in step.dependencies
            ):
                step.status = TaskStatus.FAILED
                step.error = "Step dependency is not completed"
                raise RuntimeError(step.error)
            step.status = TaskStatus.RUNNING
            self._record(events, context, "step_started", {"step_id": step.step_id, "action": step.action})
            try:
                observation = await self._run_step(
                    context,
                    step,
                    events,
                    session_id=session_id,
                    user_id=user_id,
                )
                context.observations.append(observation)
                step.result = observation.output
                if observation.status != TaskStatus.COMPLETED:
                    step.status = TaskStatus.FAILED
                    context.status = TaskStatus.FAILED
                    step.error = observation.error or "Tool execution failed"
                    self._record(events, context, "step_failed", {"step_id": step.step_id, "error": step.error})
                    return AgentRunResult(False, None, context, events, step.error)
                step.status = TaskStatus.COMPLETED
                final_output = observation.output
                self._record(events, context, "observation_received", {
                    "step_id": step.step_id,
                    "tool_name": observation.tool_name,
                    "status": observation.status.value,
                })
            except asyncio.CancelledError:
                step.status = TaskStatus.CANCELLED
                raise
            except Exception as exc:
                step.status = TaskStatus.FAILED
                context.status = TaskStatus.FAILED
                step.error = str(exc)
                self._record(events, context, "step_failed", {"step_id": step.step_id, "error": str(exc)})
                return AgentRunResult(False, None, context, events, str(exc))
        context.status = TaskStatus.COMPLETED
        self._record(events, context, "task_completed", {"steps": context.steps_completed})
        return AgentRunResult(True, final_output, context, events)

    async def _run_step(
        self,
        context: AgentExecutionContext,
        step: PlanStep,
        events: List[AgentTraceEvent],
        *,
        session_id: str,
        user_id: Optional[str],
    ) -> Observation:
        if self.reasoner is not None:
            value = self.reasoner(context, step, context.observations)
            value = await value if inspect.isawaitable(value) else value
            if isinstance(value, Observation):
                return value
        call = ToolCall(tool_name=step.action, arguments={"goal": context.goal, "objective": step.objective})
        self._record(events, context, "tool_requested", {"tool_name": call.tool_name, "execution_id": call.execution_id})
        return await self.tool_executor.execute(call, session_id=session_id, user_id=user_id)

    def cancel(self, task_id: str) -> bool:
        task = self._active.get(task_id)
        if task is None or task.done():
            return False
        task.cancel()
        return True

    def get_trace(self, task_id: str) -> List[AgentTraceEvent]:
        return list(self._traces.get(task_id, []))

    def active_count(self) -> int:
        return len(self._active)

    @staticmethod
    def _record(
        events: List[AgentTraceEvent],
        context: AgentExecutionContext,
        event: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> None:
        events.append(AgentTraceEvent(event=event, task_id=context.task_id, data=data or {}))
