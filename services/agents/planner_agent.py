"""Planner adapter compatible with the canonical Phase 5 runtime."""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

from brain.prompts.unified_prompt_builder import PromptMode, UnifiedPromptBuilder

from .base_agent import AgentContext, AgentResult, AgentStep, BaseAgent
from .contracts import AgentExecutionContext, ExecutionPlan, PlanStep

logger = logging.getLogger(__name__)


class PlannerAgent(BaseAgent):
    """Produces typed executable plans through central prompt/model authorities."""

    def __init__(
        self,
        llm: Optional[Any] = None,
        *,
        model_router: Optional[Any] = None,
        prompt_builder: Optional[UnifiedPromptBuilder] = None,
        max_steps: int = 10,
        **kwargs: Any,
    ) -> None:
        super().__init__(name="planner", description="Produces executable plans", llm=llm, max_iterations=max_steps, **kwargs)
        self._model_router = model_router
        self._prompt_builder = prompt_builder
        self._max_steps = max_steps

    async def create_plan(self, context: AgentExecutionContext) -> ExecutionPlan:
        if self._model_router is None or self._prompt_builder is None:
            raise RuntimeError("Canonical planner requires ModelRouter and UnifiedPromptBuilder")
        prompt = self._prompt_builder.build(
            context.goal,
            mode=PromptMode.AGENT,
            tools=[],
            context={"instruction": "Return JSON steps with action names only; do not invent unavailable tools."},
        )
        result = await self._model_router.route(
            messages=prompt.messages,
            capability="reasoning",
            budget_tokens=1024,
            prefer_local=True,
            request_id=context.task_id,
        )
        if not result.success or not result.response:
            raise RuntimeError(result.error or "Planner model route unavailable")
        try:
            payload = json.loads(result.response)
            raw_steps = payload.get("steps")
            if not isinstance(raw_steps, list) or not raw_steps:
                raise ValueError("steps must be a non-empty list")
            steps: List[PlanStep] = []
            for item in raw_steps[: self._max_steps]:
                if isinstance(item, str):
                    objective, action = item, item.split(":", 1)[0].strip()
                elif isinstance(item, dict):
                    objective = str(item.get("objective", "")).strip()
                    action = str(item.get("action", "")).strip()
                else:
                    raise ValueError("malformed plan step")
                if not objective or not action:
                    raise ValueError("plan step requires objective and action")
                steps.append(PlanStep(objective=objective, action=action))
            if not steps:
                raise ValueError("plan has no executable steps")
            return ExecutionPlan(goal=context.goal, steps=steps, max_steps=self._max_steps)
        except (TypeError, ValueError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"Malformed planner output: {exc}") from exc

    async def _execute(self, context: AgentContext) -> AgentResult:
        """Legacy compatibility surface; canonical runtime uses create_plan()."""
        if self._model_router is not None:
            raise RuntimeError("Use create_plan() through AgentOrchestrator")
        steps = [
            f"Understand the goal: {context.goal}",
            "Gather relevant information",
            "Identify key sub-tasks",
            "Execute each sub-task in order",
            "Verify results and summarize",
        ][: self._max_steps]
        context.memory["plan"] = steps
        return AgentResult(
            success=True,
            output="\n".join(f"{i}. {step}" for i, step in enumerate(steps, 1)),
            steps=[AgentStep(action="legacy_plan", observation=f"Generated {len(steps)} steps", result=steps)],
            context=context,
        )
