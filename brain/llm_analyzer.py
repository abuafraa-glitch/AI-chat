"""Structured request analysis through the canonical provider boundary."""
from __future__ import annotations

import json
import os
from typing import List, Literal

from pydantic import BaseModel, ValidationError

from core.llm.base import LLMConfig, LLMMessage, LLMRequest
from core.llm.provider_registry import ProviderRegistry


class LLMAnalysisResult(BaseModel):
    intent: Literal[
        "question", "task", "creative", "analysis", "code", "research",
        "training", "data", "conversation", "planning",
    ]
    complexity: Literal["simple", "medium", "complex", "enterprise"]
    domain: str
    sub_tasks: List[str]
    required_tools: List[str]
    suitable_models: List[str]
    final_objective: str


_SYSTEM_PROMPT = """
أنت مساعد ذكاء اصطناعي متقدم مهمتك تحليل طلبات المستخدمين بدقة عالية.
استخلص النية، مستوى التعقيد، المجال، المهام الفرعية، الأدوات المطلوبة، والنماذج المناسبة.
أعد JSON فقط وفق المخطط المحدد. النيات المحتملة: question, task, creative, analysis,
code, research, training, data, conversation, planning. مستويات التعقيد: simple,
medium, complex, enterprise.
"""


def _parse_analysis(content: str) -> LLMAnalysisResult:
    """Parse provider text without silently accepting an invalid contract."""
    try:
        return LLMAnalysisResult.model_validate_json(content)
    except (ValidationError, ValueError):
        start, end = content.find("{"), content.rfind("}")
        if start < 0 or end <= start:
            raise ValueError("provider_analysis_invalid_json")
        try:
            return LLMAnalysisResult.model_validate(json.loads(content[start:end + 1]))
        except (ValidationError, ValueError, json.JSONDecodeError) as exc:
            raise ValueError("provider_analysis_schema_mismatch") from exc


async def analyze_with_llm(user_request: str) -> LLMAnalysisResult:
    """Analyze a request through ProviderRegistry; no provider SDK bypass."""
    if not user_request or not user_request.strip():
        raise ValueError("user_request_required")

    provider_name = os.getenv("PROVIDER", "openai")
    model_name = os.getenv("MODEL_ID", "gpt-4o")
    ProviderRegistry.auto_register_defaults()
    provider = ProviderRegistry.create(
        provider_name,
        LLMConfig(
            provider=provider_name,
            model=model_name,
            api_key=os.getenv("OPENAI_API_KEY"),
            api_base=os.getenv("OPENAI_API_BASE"),
            temperature=0.0,
            max_tokens=1024,
            extra={"structured_output": True},
        ),
    )
    response = await provider.complete(
        LLMRequest(
            messages=[
                LLMMessage(role="system", content=_SYSTEM_PROMPT),
                LLMMessage(role="user", content=user_request),
            ],
            model=model_name,
            temperature=0.0,
            max_tokens=1024,
        )
    )
    return _parse_analysis(response.content)
