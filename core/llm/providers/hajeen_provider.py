"""Hajeen Model adapter used by the Platform ModelRouter."""
from __future__ import annotations

import logging
from typing import AsyncGenerator

from hajeen_model.inference.hajeen_provider import HajeenProvider as LocalHajeenModel

from ..base import (
    BaseLLMProvider,
    LLMConfig,
    LLMProviderError,
    LLMRequest,
    LLMResponse,
    LLMStreamChunk,
)

logger = logging.getLogger(__name__)


class HajeenLLMProvider(BaseLLMProvider):
    """Adapter for a real local Hajeen checkpoint; never fabricates output."""

    def __init__(self, config: LLMConfig):
        super().__init__(config)
        self.local_model = LocalHajeenModel(model_path=config.extra.get("model_path"))

    async def initialize(self) -> None:
        # Loading is intentionally deferred to inference/health_check so startup
        # does not claim a checkpoint exists when it does not.
        self._initialized = True

    async def _complete_implementation(self, request: LLMRequest) -> LLMResponse:
        prompt = "\n".join(f"{message.role}: {message.content}" for message in request.messages)
        if not prompt.strip():
            raise LLMProviderError("Hajeen request has no prompt")
        content = self.local_model.generate(prompt, max_new_tokens=request.max_tokens or self.config.max_tokens)
        if not content:
            raise LLMProviderError("Hajeen model returned an empty response")
        prompt_tokens = len(prompt.split())
        completion_tokens = len(content.split())
        return LLMResponse(content=content, model=self.model_name, provider=self.provider_name, prompt_tokens=prompt_tokens, completion_tokens=completion_tokens, total_tokens=prompt_tokens + completion_tokens, request_id=request.request_id)

    async def _stream_implementation(self, request: LLMRequest) -> AsyncGenerator[LLMStreamChunk, None]:
        raise LLMProviderError("Hajeen checkpoint adapter does not expose native streaming")
        yield  # pragma: no cover

    async def health_check(self) -> bool:
        try:
            return bool(self.local_model.load_model())
        except Exception as exc:
            logger.warning("Hajeen checkpoint unavailable: %s", exc)
            return False


__all__ = ["HajeenLLMProvider"]
