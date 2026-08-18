"""Central model selection and execution authority for Hajeen Platform."""
from __future__ import annotations

import asyncio
import logging
import os
import time
from dataclasses import dataclass, field
from typing import Any, AsyncGenerator, Dict, List, Optional

from core.llm.base import LLMConfig, LLMMessage, LLMRequest, LLMResponse, LLMStreamChunk
from core.llm.provider_registry import ProviderRegistry

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ModelConfig:
    """Runtime model descriptor; metadata alone never implies availability."""

    model_id: str
    provider: str
    base_url: Optional[str]
    api_key: Optional[str]
    capabilities: List[str]
    context_limit: int
    max_tokens: int
    avg_latency_ms: float
    cost_per_1k_tokens: float
    quality_score: float
    is_local: bool
    available: bool = False
    health: Optional[bool] = None

    @property
    def context_length(self) -> int:
        return self.context_limit


@dataclass
class RouteResult:
    model_id: str
    provider: str
    latency_ms: float
    tokens_used: int
    response: str
    success: bool
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def prompt_tokens(self) -> int:
        return int(self.metadata.get("prompt_tokens", 0))

    @property
    def completion_tokens(self) -> int:
        return int(self.metadata.get("completion_tokens", self.tokens_used))


DEFAULT_MODELS: Dict[str, ModelConfig] = {
    "ollama/llama3": ModelConfig("llama3", "ollama", "http://localhost:11434", None, ["general", "rag", "conversation"], 8192, 4096, 800, 0.0, 0.78, True),
    "ollama/qwen2.5": ModelConfig("qwen2.5:7b", "ollama", "http://localhost:11434", None, ["arabic", "general", "code", "rag"], 32768, 8192, 1000, 0.0, 0.82, True),
    "ollama/qwen2.5-coder": ModelConfig("qwen2.5-coder:7b", "ollama", "http://localhost:11434", None, ["code"], 32768, 8192, 900, 0.0, 0.85, True),
    "openai/gpt-4o": ModelConfig("gpt-4o", "openai", None, "env:OPENAI_API_KEY", ["general", "code", "math", "analysis", "creative", "rag"], 128000, 4096, 2000, 5.0, 0.97, False),
    "openai/gpt-4o-mini": ModelConfig("gpt-4o-mini", "openai", None, "env:OPENAI_API_KEY", ["general", "code", "math", "analysis", "rag"], 128000, 4096, 800, 0.15, 0.88, False),
    "hajeen-local": ModelConfig("hajeen-v1", "local", None, None, ["arabic", "general", "rag"], 4096, 4096, 500, 0.0, 0.70, True),
}


def _score_model(model: ModelConfig, capability: str, budget_tokens: int, prefer_local: bool = False) -> float:
    if budget_tokens > model.max_tokens or budget_tokens > model.context_limit:
        return float("-inf")
    cap_score = 1.0 if capability in model.capabilities else 0.0
    if capability not in model.capabilities and capability not in {"general", "conversation"}:
        return float("-inf")
    local_bonus = 0.12 if prefer_local and model.is_local else 0.0
    cost_score = 1.0 if model.cost_per_1k_tokens == 0 else max(0.1, 1 - model.cost_per_1k_tokens / 10)
    speed_score = max(0.1, 1 - model.avg_latency_ms / 5000)
    return model.quality_score * 0.4 + cap_score * 0.3 + cost_score * 0.2 + speed_score * 0.1 + local_bonus


class ModelRouter:
    """The only authority allowed to select and execute a model provider."""

    def __init__(self, prefer_local: bool = True) -> None:
        self._models = dict(DEFAULT_MODELS)
        self._prefer_local = prefer_local
        self._routing_history: List[Dict[str, Any]] = []
        self._provider_registry: Dict[str, Any] = {}
        self._provider_init_lock = asyncio.Lock()

    @property
    def models(self) -> Dict[str, ModelConfig]:
        return dict(self._models)

    def register_provider(self, model_key: str, provider_instance: Any) -> None:
        """Register a real provider instance, primarily for application wiring/tests."""
        if model_key not in self._models:
            raise KeyError(f"Unknown model key: {model_key}")
        self._provider_registry[model_key] = provider_instance

    def add_model(self, key: str, config: ModelConfig) -> None:
        self._models[key] = config

    def _resolve_key(self, identifier: str) -> Optional[str]:
        if identifier in self._models:
            return identifier
        for key, cfg in self._models.items():
            if cfg.model_id == identifier or f"{cfg.provider}/{cfg.model_id}" == identifier:
                return key
        return None

    def select_model(self, capability: str = "general", budget_tokens: int = 4096, force_local: bool = False, exclude: Optional[List[str]] = None) -> Optional[str]:
        exclude_set = set(exclude or [])
        candidates = [(key, cfg) for key, cfg in self._models.items() if key not in exclude_set and _score_model(cfg, capability, budget_tokens) != float("-inf")]
        registered = [(key, cfg) for key, cfg in candidates if key in self._provider_registry]
        if registered:
            candidates = registered
        if force_local or self._prefer_local:
            local = [(key, cfg) for key, cfg in candidates if cfg.is_local]
            if local:
                candidates = local
        if not candidates:
            return None
        return max(candidates, key=lambda pair: _score_model(pair[1], capability, budget_tokens, force_local or self._prefer_local))[0]

    async def _get_provider(self, key: str, cfg: ModelConfig) -> Any:
        provider = self._provider_registry.get(key)
        if provider is not None:
            if not getattr(provider, "_initialized", False) and hasattr(provider, "initialize"):
                await provider.initialize()
            return provider
        async with self._provider_init_lock:
            provider = self._provider_registry.get(key)
            if provider is not None:
                return provider
            ProviderRegistry.auto_register_defaults()
            # `local` is the platform-level provider classification for the
            # Hajeen local model; the concrete adapter remains Hajeen Model.
            adapter_name = "hajeen" if key == "hajeen-local" else cfg.provider
            provider_cls = ProviderRegistry.get(adapter_name)
            if provider_cls is None:
                raise RuntimeError(f"No registered provider adapter for {adapter_name!r}")
            api_key = os.getenv("OPENAI_API_KEY") if cfg.api_key == "env:OPENAI_API_KEY" else cfg.api_key
            provider = provider_cls(LLMConfig(provider=adapter_name, model=cfg.model_id, api_key=api_key, api_base=cfg.base_url, max_tokens=cfg.max_tokens))
            await provider.initialize()
            self._provider_registry[key] = provider
            return provider

    @staticmethod
    def _request(messages: List[Dict[str, str]], cfg: ModelConfig, budget_tokens: int, request_id: Optional[str] = None, stream: bool = False) -> LLMRequest:
        return LLMRequest(messages=[LLMMessage(role=m["role"], content=m["content"]) for m in messages], model=cfg.model_id, max_tokens=min(budget_tokens, cfg.max_tokens), stream=stream, request_id=request_id)

    async def route(self, messages: List[Dict[str, str]], capability: str = "general", budget_tokens: int = 4096, force_model: Optional[str] = None, timeout: float = 60.0, prefer_local: Optional[bool] = None, request_id: Optional[str] = None) -> RouteResult:
        local_preference = self._prefer_local if prefer_local is None else prefer_local
        forced_key = self._resolve_key(force_model) if force_model else None
        if force_model and forced_key is None:
            return RouteResult(force_model, "none", 0.0, 0, "", False, "Requested model is not registered", {"fail_closed": True})
        tried: List[str] = []
        key = forced_key or self.select_model(capability, budget_tokens, force_local=local_preference)
        last_error = "No eligible model is registered"
        while key and key not in tried:
            tried.append(key)
            cfg = self._models[key]
            started = time.perf_counter()
            try:
                provider = await asyncio.wait_for(self._get_provider(key, cfg), timeout=timeout)
                request = self._request(messages, cfg, budget_tokens, request_id=request_id)
                if hasattr(provider, "complete"):
                    response: LLMResponse = await asyncio.wait_for(provider.complete(request), timeout=timeout)
                elif key in self._provider_registry and hasattr(provider, "chat"):
                    # Explicitly registered test/application adapter compatibility.
                    raw = await asyncio.wait_for(provider.chat(messages[-1]["content"] if messages else ""), timeout=timeout)
                    text = raw.get("content", "") if isinstance(raw, dict) else str(raw)
                    response = LLMResponse(content=text, model=cfg.model_id, provider=cfg.provider, completion_tokens=len(text.split()), total_tokens=len(text.split()))
                else:
                    raise RuntimeError("Provider adapter does not expose complete()")
                if not response.content:
                    raise RuntimeError("Provider returned an empty response")
                latency = (time.perf_counter() - started) * 1000
                self._record_routing(key, capability, latency, True)
                return RouteResult(key, cfg.provider, latency, response.total_tokens or len(response.content.split()), response.content, True, metadata={"prompt_tokens": response.prompt_tokens, "completion_tokens": response.completion_tokens, "finish_reason": response.finish_reason})
            except Exception as exc:
                last_error = str(exc)
                self._record_routing(key, capability, (time.perf_counter() - started) * 1000, False)
                logger.warning("model_router: %s failed closed: %s", key, exc)
                if forced_key:
                    break
                key = self.select_model(capability, budget_tokens, force_local=local_preference, exclude=tried)
        return RouteResult(tried[-1] if tried else "none", "none", 0.0, 0, "", False, last_error, {"fail_closed": True, "tried": tried})

    async def stream(self, messages: List[Dict[str, str]], capability: str = "general", budget_tokens: int = 4096, force_model: Optional[str] = None, timeout: float = 60.0, prefer_local: Optional[bool] = None, request_id: Optional[str] = None) -> AsyncGenerator[LLMStreamChunk, None]:
        local_preference = self._prefer_local if prefer_local is None else prefer_local
        key = self._resolve_key(force_model) if force_model else self.select_model(capability, budget_tokens, force_local=local_preference)
        if force_model and key is None:
            raise RuntimeError("Requested model is not registered")
        if key is None:
            raise RuntimeError("No eligible model is registered")
        cfg = self._models[key]
        provider = await asyncio.wait_for(self._get_provider(key, cfg), timeout=timeout)
        request = self._request(messages, cfg, budget_tokens, request_id=request_id, stream=True)
        if not hasattr(provider, "stream"):
            raise RuntimeError(f"Provider {cfg.provider!r} does not expose native streaming")
        async for chunk in provider.stream(request):
            if not isinstance(chunk, LLMStreamChunk):
                raise RuntimeError("Provider returned an invalid stream chunk")
            yield chunk

    async def list_available_models(self, capability: str = "general", budget_tokens: int = 4096) -> List[Dict[str, Any]]:
        result = []
        for key, cfg in self._models.items():
            entry = {"key": key, "model_id": cfg.model_id, "provider": cfg.provider, "capabilities": cfg.capabilities, "context_limit": cfg.context_limit, "max_tokens": cfg.max_tokens, "is_local": cfg.is_local, "available": key in self._provider_registry}
            provider = self._provider_registry.get(key)
            if provider is not None and hasattr(provider, "health_check"):
                try:
                    entry["health"] = await provider.health_check()
                    entry["available"] = bool(entry["health"])
                except Exception:
                    entry["health"] = False
                    entry["available"] = False
            result.append(entry)
        return result

    def _record_routing(self, model_key: str, capability: str, latency_ms: float, success: bool) -> None:
        self._routing_history.append({"model": model_key, "capability": capability, "latency_ms": latency_ms, "success": success, "at": time.time()})
        self._routing_history = self._routing_history[-1000:]

    def get_routing_stats(self) -> Dict[str, Any]:
        if not self._routing_history:
            return {"total": 0}
        total = len(self._routing_history)
        return {"total": total, "success_rate": round(sum(r["success"] for r in self._routing_history) / total, 3), "by_model": {k: sum(1 for r in self._routing_history if r["model"] == k) for k in {r["model"] for r in self._routing_history}}, "avg_latency_ms": round(sum(r["latency_ms"] for r in self._routing_history) / total, 1)}


_router: Optional[ModelRouter] = None


def get_model_router() -> ModelRouter:
    global _router
    if _router is None:
        _router = ModelRouter()
    return _router


def set_model_router(router: ModelRouter) -> None:
    global _router
    _router = router


__all__ = ["ModelConfig", "RouteResult", "ModelRouter", "get_model_router", "set_model_router"]
