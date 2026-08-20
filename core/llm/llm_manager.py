"""Phase 8.1 — LLM Manager: إدارة مزودي النماذج مع نظام Fallback."""
from __future__ import annotations

import asyncio
import logging
from typing import AsyncGenerator, Dict, List, Optional

from aiobreaker import CircuitBreakerError

from .base import (
    BaseLLMProvider,
    LLMError,
    LLMRequest,
    LLMResponse,
    LLMStreamChunk,
)
from .config import LLMSettings
from .provider_registry import ProviderRegistry

logger = logging.getLogger(__name__)

_manager_instance: Optional["LLMManager"] = None


class LLMManager:
    """
    مدير مركزي لمزودي LLM مع:
    - Provider fallback system
    - Dynamic provider switching
    - Async inference
    - Token streaming
    - Health monitoring
    """

    def __init__(
        self,
        primary_provider: Optional[str] = None,
        fallback_providers: Optional[List[str]] = None,
        settings: Optional[LLMSettings] = None,
    ):
        self.settings = settings or LLMSettings.from_env()
        self._primary_name = primary_provider or self.settings.provider
        self._fallback_names = fallback_providers or []
        self._providers: Dict[str, BaseLLMProvider] = {}
        self._initialized = False
        # Compatibility facade: ModelRouter remains the sole selection authority.
        from brain.model_router import ModelRouter
        self._router = ModelRouter(prefer_local=self.settings.provider in {"local", "hajeen"})

    async def initialize(self) -> None:
        """تهيئة المدير وتسجيل المزودين الافتراضيين."""
        if self._initialized:
            return

        ProviderRegistry.auto_register_defaults()

        # تهيئة المزود الرئيسي
        await self._ensure_provider(self._primary_name)

        # تهيئة مزودي الـ fallback
        for name in self._fallback_names:
            try:
                await self._ensure_provider(name)
            except Exception as e:
                logger.warning("Fallback provider '%s' unavailable: %s", name, e)

        self._initialized = True
        logger.info(
            "LLM Manager initialized: primary=%s, fallbacks=%s",
            self._primary_name,
            self._fallback_names,
        )

    async def _ensure_provider(self, name: str) -> BaseLLMProvider:
        """التأكد من وجود مزود وتهيئته."""
        if name not in self._providers:
            config = self.settings.to_llm_config()
            config.provider = name
            provider = ProviderRegistry.create(name, config)
            await provider.initialize()
            self._providers[name] = provider
            if name not in self._router.models:
                # A caller-supplied provider is explicit; expose only that
                # descriptor to the central router, never as an auto-default.
                from brain.model_router import ModelConfig
                self._router.add_model(
                    name,
                    ModelConfig(
                        model_id=getattr(provider, "model_name", name),
                        provider=name,
                        base_url=None,
                        api_key=None,
                        capabilities=["general", "conversation", "rag"],
                        context_limit=max(self.settings.max_tokens, 4096),
                        max_tokens=self.settings.max_tokens,
                        avg_latency_ms=0.0,
                        cost_per_1k_tokens=0.0,
                        quality_score=0.0,
                        is_local=False,
                        available=True,
                    ),
                )
            self._router.register_provider(name, provider)
        return self._providers[name]

    @property
    def primary_provider(self) -> BaseLLMProvider:
        if self._primary_name not in self._providers:
            raise LLMError("Manager not initialized. Call initialize() first.")
        return self._providers[self._primary_name]

    async def complete(
        self,
        request: LLMRequest,
        provider_name: Optional[str] = None,
    ) -> LLMResponse:
        """
        تنفيذ inference مع fallback system.

        يحاول المزود الرئيسي أولاً، ثم المزودين البدلاء عند الفشل.
        """
        if not self._initialized:
            await self.initialize()

        await self._ensure_provider(provider_name or self._primary_name)
        result = await self._router.route(
            messages=request.to_messages_list(),
            capability="general",
            budget_tokens=request.max_tokens or self.settings.max_tokens,
            force_model=provider_name or self._primary_name,
            request_id=request.request_id,
        )
        if not result.success:
            raise LLMError(result.error or "ModelRouter returned an unsuccessful result")
        return LLMResponse(
            content=result.response,
            model=result.model_id or request.model or self.settings.model,
            provider=result.provider,
            prompt_tokens=result.prompt_tokens,
            completion_tokens=result.completion_tokens,
            total_tokens=result.tokens_used,
            finish_reason="stop",
            request_id=request.request_id,
        )

    async def generate(
        self,
        prompt: str,
        model: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        provider_name: Optional[str] = None,
    ) -> str:
        """Compatibility adapter for cognitive analyzers; delegates to complete()."""
        from .base import LLMMessage

        request = LLMRequest(
            messages=[LLMMessage(role="user", content=prompt)],
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        response = await self.complete(request, provider_name=provider_name)
        return response.content

    async def stream(
        self,
        request: LLMRequest,
        provider_name: Optional[str] = None,
    ) -> AsyncGenerator[LLMStreamChunk, None]:
        """تنفيذ streaming inference."""
        if not self._initialized:
            await self.initialize()

        await self._ensure_provider(provider_name or self._primary_name)
        request.stream = True
        async for chunk in self._router.stream(
            messages=request.to_messages_list(),
            capability="general",
            budget_tokens=request.max_tokens or self.settings.max_tokens,
            force_model=provider_name or self._primary_name,
            request_id=request.request_id,
        ):
            yield chunk

    async def health_check_all(self) -> Dict[str, bool]:
        """فحص صحة جميع المزودين."""
        if not self._initialized:
            await self.initialize()

        results = {}
        tasks = {
            name: provider.health_check()
            for name, provider in self._providers.items()
        }
        for name, task in tasks.items():
            try:
                results[name] = await asyncio.wait_for(task, timeout=10.0)
            except Exception:
                results[name] = False
        return results

    async def switch_primary(self, new_provider: str) -> None:
        """تغيير المزود الرئيسي بدون إعادة تشغيل النظام."""
        await self._ensure_provider(new_provider)
        old = self._primary_name
        self._primary_name = new_provider
        logger.info("Switched primary provider: %s → %s", old, new_provider)

    def get_provider_names(self) -> List[str]:
        return list(self._providers.keys())

    async def get_available_models(self) -> Dict[str, str]:
        """قائمة بالنماذج المتاحة لكل مزود."""
        if not self._initialized:
            await self.initialize()
        return {
            name: provider.model_name
            for name, provider in self._providers.items()
        }


def get_llm_manager() -> LLMManager:
    """Return the lazy singleton; callers explicitly await ``initialize``."""
    global _manager_instance
    if _manager_instance is None:
        _manager_instance = LLMManager()
    return _manager_instance


def set_llm_manager(manager: LLMManager) -> None:
    """تعيين instance مخصص (للاختبار)."""
    global _manager_instance
    _manager_instance = manager
