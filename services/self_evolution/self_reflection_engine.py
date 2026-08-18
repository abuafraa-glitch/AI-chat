from __future__ import annotations

import json
from typing import Any, Awaitable, Callable, Dict, Iterable


class MockLLM:
    """Test fixture adapter only; production callers must inject a real callable."""
    async def __call__(self, prompt: str) -> str:
        if prompt.startswith("Critique"):
            return json.dumps({"scores": {"logic": 4, "efficiency": 4}, "critique": "Plan is logical but could be more efficient.", "improvements": ["Combine steps Y and Z."]})
        return json.dumps({"scores": {"accuracy": 4, "completeness": 4}, "critique": "Output was mostly accurate but lacked some details.", "improvements": ["Add more details to X."]})


class SelfReflectionEngine:
    def __init__(self, llm_inference_function: Callable[..., Awaitable[Any]]) -> None:
        self.llm_inference_function = llm_inference_function

    async def _invoke(self, prompt: str) -> Dict[str, Any]:
        raw = await self.llm_inference_function(prompt)
        if isinstance(raw, dict):
            return raw
        return json.loads(raw)

    async def reflect_on_output(self, original_prompt: str, agent_output: str, criteria: Iterable[str]) -> Dict[str, Any]:
        try:
            result = await self._invoke(f"Reflect on prompt={original_prompt}; output={agent_output}; criteria={list(criteria)}")
            return result
        except Exception as exc:
            return {"error": str(exc), "scores": {}, "critique": "Failed to perform self-reflection.", "improvements": []}

    async def critique_plan(self, original_goal: str, agent_plan: Iterable[str], criteria: Iterable[str]) -> Dict[str, Any]:
        try:
            result = await self._invoke(f"Critique goal={original_goal}; plan={list(agent_plan)}; criteria={list(criteria)}")
            return result
        except Exception as exc:
            return {"error": str(exc), "scores": {}, "critique": "Failed to critique plan.", "improvements": []}
