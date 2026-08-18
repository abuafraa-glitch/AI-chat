"""Acceptance tests for the canonical Phase 5 agent runtime."""
from __future__ import annotations

import asyncio

import pytest

from brain.brain_v3 import HajeenBrainV3
from brain.memory.memory_fabric import get_memory_fabric
from brain.model_router import get_model_router
from brain.policy.policy_engine import get_policy_engine
from brain.prompts.unified_prompt_builder import UnifiedPromptBuilder
from services.agents.agent_orchestrator import AgentOrchestrator
from services.agents.contracts import ExecutionPlan, PlanStep, TaskStatus, ToolSpec
from services.agents.planner_agent import PlannerAgent
from services.agents.tool_runtime import ToolExecutor, ToolRegistry


@pytest.fixture
def runtime():
    registry = ToolRegistry()
    policy = get_policy_engine()
    executor = ToolExecutor(registry, policy)
    orchestrator = AgentOrchestrator(
        model_router=get_model_router(),
        memory_fabric=get_memory_fabric(),
        prompt_builder=UnifiedPromptBuilder(),
        policy_engine=policy,
        tool_registry=registry,
        tool_executor=executor,
        max_steps=3,
        execution_timeout_seconds=2,
    )
    return registry, orchestrator


@pytest.mark.asyncio
async def test_orchestrator_executes_typed_plan_and_records_lifecycle(runtime):
    registry, orchestrator = runtime
    registry.register(ToolSpec(
        name="echo",
        description="Returns the supplied objective for deterministic integration testing.",
        input_schema={"type": "object"},
        output_schema={"type": "string"},
        handler=lambda goal, objective: f"{goal}:{objective}",
        idempotent=True,
    ))
    plan = ExecutionPlan(goal="inspect", steps=[PlanStep(objective="inspect", action="echo")])
    result = await orchestrator.run("inspect", session_id="phase5", plan=plan)
    assert result.success is True
    assert result.context.status == TaskStatus.COMPLETED
    assert result.context.steps_completed == 1
    assert result.output == "inspect:inspect"
    assert [event.event for event in result.events] == [
        "task_started", "plan_created", "step_started", "tool_requested",
        "observation_received", "task_completed",
    ]


@pytest.mark.asyncio
async def test_dangerous_tool_is_denied_without_permission(runtime):
    registry, orchestrator = runtime
    registry.register(ToolSpec(
        name="dangerous_action",
        description="A permission-protected operation.",
        input_schema={"type": "object"},
        output_schema={"type": "string"},
        permissions=frozenset({"execute:dangerous"}),
        dangerous=True,
        handler=lambda **_: "must not run",
    ))
    result = await orchestrator.run(
        "restricted",
        session_id="phase5",
        plan=ExecutionPlan(goal="restricted", steps=[PlanStep(objective="restricted", action="dangerous_action")]),
    )
    assert result.success is False
    assert result.context.status == TaskStatus.FAILED
    assert result.error == "Tool permission denied"
    assert result.context.observations[0].metadata["security"] == "denied"


@pytest.mark.asyncio
async def test_tool_timeout_is_fail_closed(runtime):
    registry, orchestrator = runtime

    async def slow(**_: object) -> str:
        await asyncio.sleep(0.2)
        return "late"

    registry.register(ToolSpec(
        name="slow",
        description="Timeout test tool.",
        input_schema={"type": "object"},
        output_schema={"type": "string"},
        timeout_seconds=0.01,
        handler=slow,
    ))
    result = await orchestrator.run(
        "timeout",
        session_id="phase5",
        plan=ExecutionPlan(goal="timeout", steps=[PlanStep(objective="timeout", action="slow")]),
    )
    assert result.success is False
    assert result.error == "Tool timeout after 0.01s"
    assert result.context.observations[0].metadata["timeout"] is True


@pytest.mark.asyncio
async def test_orchestrator_propagates_cancellation(runtime):
    registry, orchestrator = runtime

    async def slow(**_: object) -> str:
        await asyncio.sleep(5)
        return "late"

    registry.register(ToolSpec(
        name="cancel_me",
        description="Cancellation test tool.",
        input_schema={"type": "object"},
        output_schema={"type": "string"},
        handler=slow,
    ))
    task = asyncio.create_task(orchestrator.run(
        "cancel",
        session_id="phase5",
        plan=ExecutionPlan(goal="cancel", steps=[PlanStep(objective="cancel", action="cancel_me")]),
    ))
    await asyncio.sleep(0.01)
    task.cancel()
    with pytest.raises(asyncio.CancelledError):
        await task


def test_brain_injects_canonical_agent_authorities():
    brain = HajeenBrainV3()
    assert brain.agent_orchestrator.model_router is brain.model_router
    assert brain.agent_orchestrator.memory_fabric is brain.memory
    assert brain.agent_orchestrator.prompt_builder is brain.prompt_builder
    assert brain.agent_orchestrator.policy_engine is brain.policy


@pytest.mark.asyncio
async def test_planner_fails_closed_without_central_dependencies():
    planner = PlannerAgent(model_router=None, prompt_builder=None)
    with pytest.raises(RuntimeError, match="Canonical planner requires"):
        await planner.create_plan(type("Ctx", (), {"goal": "x", "task_id": "t"})())
