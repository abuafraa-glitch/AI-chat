from __future__ import annotations

from typing import Any, Awaitable, Callable, Iterable


class ContinuousLearningLoop:
    def __init__(self, llm_inference_function: Callable[..., Awaitable[Any]], reflection_engine: Any, episodic_memory: Any, curiosity_engine: Any) -> None:
        self.llm_inference_function = llm_inference_function
        self.reflection_engine = reflection_engine
        self.episodic_memory = episodic_memory
        self.curiosity_engine = curiosity_engine

    async def execute_and_learn(self, task_prompt: str, agent_action_function: Callable[..., Awaitable[dict]], available_tools: Iterable[Any]) -> dict:
        original = await agent_action_function(task_prompt, available_tools)
        reflection = await self.reflection_engine.reflect_on_output(task_prompt, original.get("output", ""), ["accuracy", "completeness", "relevance"])
        scores = reflection.get("scores", {})
        reflection_score = min(scores.values()) if scores else 0
        success = bool(original.get("success")) and reflection_score >= 3
        self.episodic_memory.add_experience(
            prompt=task_prompt,
            actions=original.get("actions_taken", []),
            outcome=original.get("output", ""),
            success=success,
            metadata={"reflection": reflection},
        )
        recent_failures = len(self.episodic_memory.get_failed_experiences())
        explore = await self.curiosity_engine.decide_to_explore({}, float(original.get("confidence", 0.0)), recent_failures)
        if not explore:
            return {"status": "completed", "original_output": original, "reflection": reflection}
        strategy = await self.curiosity_engine.suggest_exploration_strategy({}, available_tools)
        self.episodic_memory.add_experience(
            prompt=f"Exploration for: {task_prompt}",
            actions=strategy.get("suggested_actions", []),
            outcome=strategy.get("strategy_description", ""),
            success=False,
            metadata={"type": "exploration_strategy"},
        )
        return {"status": "exploration_suggested", "original_output": original, "reflection": reflection, "exploration_strategy": strategy}
