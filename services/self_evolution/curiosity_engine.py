from __future__ import annotations

import json
from typing import Any, Awaitable, Callable, Dict, Iterable, Optional


class CuriosityEngine:
    def __init__(self, llm_inference_function: Callable[..., Awaitable[Any]], reflection_engine: Any, episodic_memory: Any, exploration_threshold: float = 0.3, failure_threshold: int = 2) -> None:
        self.llm_inference_function = llm_inference_function
        self.reflection_engine = reflection_engine
        self.episodic_memory = episodic_memory
        self.exploration_threshold = exploration_threshold
        self.failure_threshold = failure_threshold

    async def decide_to_explore(self, current_task_context: Dict[str, Any], agent_confidence: float, recent_failures: int) -> bool:
        return agent_confidence < self.exploration_threshold or recent_failures >= self.failure_threshold

    async def _json_call(self, prompt: str) -> Dict[str, Any]:
        raw = await self.llm_inference_function(prompt)
        return raw if isinstance(raw, dict) else json.loads(raw)

    async def suggest_exploration_strategy(self, current_task_context: Dict[str, Any], available_tools: Iterable[str]) -> Dict[str, Any]:
        try:
            return await self._json_call(f"Suggest an exploration strategy for {current_task_context} using {list(available_tools)}")
        except Exception as exc:
            return {"error": str(exc), "strategy_description": "Failed to generate strategy.", "suggested_actions": []}

    async def evaluate_exploration_outcome(self, exploration_strategy: Dict[str, Any], exploration_results: Any) -> Dict[str, Any]:
        try:
            return await self._json_call(f"Evaluate strategy={exploration_strategy}; results={exploration_results}")
        except Exception as exc:
            return {"error": str(exc), "evaluation_summary": "Failed to evaluate exploration.", "success_score": 0, "lessons_learned": []}
