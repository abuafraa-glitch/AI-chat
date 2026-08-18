"""Acceptance tests for the canonical Phase 5 agent runtime."""
from __future__ import annotations

import asyncio

import pytest
from types import SimpleNamespace

from brain.brain_v3 import HajeenBrainV3
from brain.memory.memory_fabric import get_memory_fabric
from brain.model_router import get_model_router
from brain.decision_engine import DecisionEngine
from brain.goal_manager import ComplexityLevel, IntentType
from brain.policy.policy_engine import get_policy_engine
from brain.prompts.unified_prompt_builder import UnifiedPromptBuilder
from services.agents.agent_orchestrator import AgentOrchestrator
from services.agents.contracts import ExecutionPlan, PlanStep, TaskStatus, ToolCall, ToolSpec
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
async def test_tool_retry_is_limited_to_idempotent_tools_and_replays_by_key(runtime):
    registry, orchestrator = runtime
    calls = {"count": 0}

    def flaky(**_: object) -> str:
        calls["count"] += 1
        if calls["count"] < 3:
            raise RuntimeError("transient")
        return "ok"

    registry.register(ToolSpec(
        name="flaky",
        description="Retry-safe test tool.",
        input_schema={"type": "object"},
        output_schema={"type": "string"},
        idempotent=True,
        max_retries=2,
        handler=flaky,
    ))
    first = await orchestrator.tool_executor.execute(
        ToolCall(tool_name="flaky", arguments={}, idempotency_key="same"),
        session_id="phase5",
    )
    second = await orchestrator.tool_executor.execute(
        ToolCall(tool_name="flaky", arguments={}, idempotency_key="same"),
        session_id="phase5",
    )
    assert first.status == TaskStatus.COMPLETED
    assert first.metadata["attempt"] == 3
    assert second.metadata["idempotent_replay"] is True
    assert calls["count"] == 3


@pytest.mark.asyncio
async def test_unknown_tool_invalid_input_and_max_steps_fail_closed(runtime):
    registry, orchestrator = runtime
    registry.register(ToolSpec(
        name="requires_value",
        description="Validation test tool.",
        input_schema={"type": "object", "required": ["value"]},
        output_schema={"type": "string"},
        handler=lambda value: value,
    ))
    invalid = await orchestrator.tool_executor.execute(
        ToolCall(tool_name="requires_value", arguments={}), session_id="phase5"
    )
    unknown = await orchestrator.tool_executor.execute(
        ToolCall(tool_name="missing", arguments={}), session_id="phase5"
    )
    assert invalid.error.startswith("Invalid tool input")
    assert unknown.error == "Unknown tool: missing"
    plan = ExecutionPlan(goal="too many", steps=[PlanStep(objective="x", action="requires_value")] * 4, max_steps=3)
    result = await orchestrator.run("too many", session_id="phase5", plan=plan)
    assert result.success is False
    assert result.error == "Plan exceeds max_steps"


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


@pytest.mark.asyncio
async def test_decision_engine_selects_agent_only_on_explicit_opt_in():
    engine = DecisionEngine()
    goal = SimpleNamespace(domain="general", intent=IntentType.TASK, complexity=ComplexityLevel.SIMPLE)
    direct = await engine.decide("direct", goal, "simple request", context={})
    selected = await engine.decide("agent", goal, "complex task", context={"use_agent": True})
    assert direct.use_agent is False
    assert direct.metadata["agent_selection"] == "direct_model_path"
    assert selected.use_agent is True
    assert selected.metadata["agent_selection"] == "explicit_request"


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
