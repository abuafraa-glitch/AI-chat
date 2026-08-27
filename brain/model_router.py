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
from core.model.model_registry import ModelArtifactStatus, ModelRegistry

logger = logging.getLogger(__name__)

VERIFIED_BASE_MODEL_ID = "Qwen/Qwen3-30B-A3B"
VERIFIED_BASE_TARGET_COMMIT = "9d6a564f66303a3691cbb646d39a28f3eb792ca7"


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


GROQ_RUNTIME_MODEL_KEY = "groq/openai/gpt-oss-20b"
MODEL_ALIASES: Dict[str, str] = {
    "gpt-4o-mini": GROQ_RUNTIME_MODEL_KEY,
    "openai/gpt-4o-mini": GROQ_RUNTIME_MODEL_KEY,
    "gpt-4o": GROQ_RUNTIME_MODEL_KEY,
    "openai/gpt-4o": GROQ_RUNTIME_MODEL_KEY,
    "gpt-oss-20b": GROQ_RUNTIME_MODEL_KEY,
    "openai/gpt-oss-20b": GROQ_RUNTIME_MODEL_KEY,
    "groq/gpt-oss-20b": GROQ_RUNTIME_MODEL_KEY,
    "groq/openai/gpt-oss-20b": GROQ_RUNTIME_MODEL_KEY,
    "llama-3.3-70b-versatile": GROQ_RUNTIME_MODEL_KEY,
    "groq/llama-3.3-70b-versatile": GROQ_RUNTIME_MODEL_KEY,
}


DEFAULT_MODELS: Dict[str, ModelConfig] = {
    "ollama/llama3": ModelConfig("llama3", "ollama", "http://localhost:11434", None, ["general", "rag", "conversation"], 8192, 4096, 800, 0.0, 0.78, True),
    "ollama/qwen2.5": ModelConfig("qwen2.5:7b", "ollama", "http://localhost:11434", None, ["arabic", "general", "code", "rag"], 32768, 8192, 1000, 0.0, 0.82, True),
    "ollama/qwen2.5-coder": ModelConfig("qwen2.5-coder:7b", "ollama", "http://localhost:11434", None, ["code"], 32768, 8192, 900, 0.0, 0.85, True),
    "openai/gpt-4o": ModelConfig("gpt-4o", "openai", None, "env:OPENAI_API_KEY", ["general", "code", "math", "analysis", "creative", "rag"], 128000, 4096, 2000, 5.0, 0.97, False),
    "openai/gpt-4o-mini": ModelConfig("gpt-4o-mini", "openai", None, "env:OPENAI_API_KEY", ["general", "code", "math", "analysis", "rag"], 128000, 4096, 800, 0.15, 0.88, False),
    "groq/openai/gpt-oss-20b": ModelConfig("openai/gpt-oss-20b", "groq", "https://api.groq.com/openai/v1", "env:GROQ_API_KEY", ["arabic", "general", "code", "analysis", "conversation"], 131072, 8192, 450, 0.0, 0.90, False, available=bool(os.getenv("GROQ_API_KEY"))),
    "hajeen-local": ModelConfig(VERIFIED_BASE_MODEL_ID, "local", None, None, ["arabic", "general", "rag"], 32768, 8192, 500, 0.0, 0.90, True),
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

    def __init__(self, prefer_local: bool = True, model_registry: Optional[ModelRegistry] = None) -> None:
        self._models = dict(DEFAULT_MODELS)
        self._model_registry = model_registry or ModelRegistry()
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

    def set_model_registry(self, registry: ModelRegistry) -> None:
        """Inject the lifecycle registry; selection remains owned by this router."""
        self._model_registry = registry

    def _registry_record_for(self, key: str, cfg: ModelConfig) -> Any:
        getter = getattr(self._model_registry, "get_artifact", None)
        if getter is None:
            return None
        return getter(cfg.model_id, "production") or getter(key, "production")

    def _registry_eligible(self, key: str, cfg: ModelConfig) -> bool:
        """Require a commit-pinned VERIFIED_BASE for the real local Hajeen path."""
        records = getattr(self._model_registry, "list_artifacts", lambda: [])()
        related = [
            item for item in records
            if item.get("model_id") in {key, cfg.model_id, VERIFIED_BASE_MODEL_ID}
        ]
        if key == "hajeen-local" or cfg.model_id == VERIFIED_BASE_MODEL_ID:
            if key in self._provider_registry:
                return True
            return any(
                item.get("status") == ModelArtifactStatus.VERIFIED_BASE.value
                and item.get("lineage", {}).get("target_commit") == VERIFIED_BASE_TARGET_COMMIT
                for item in related
            )
        if not related:
            return True
        return any(item.get("status") in {ModelArtifactStatus.STAGING.value, ModelArtifactStatus.PRODUCTION.value} for item in related)

    def _resolve_key(self, identifier: str) -> Optional[str]:
        normalized = str(identifier).strip().lower()
        alias = MODEL_ALIASES.get(normalized)
        if alias in self._models:
            return alias
        if identifier == "hajeen-v1" and "hajeen-local" in self._models:
            return "hajeen-local"
        if identifier in self._models:
            return identifier
        for key, cfg in self._models.items():
            if cfg.model_id == identifier or f"{cfg.provider}/{cfg.model_id}" == identifier:
                return key
        return None

    def select_model(self, capability: str = "general", budget_tokens: int = 4096, force_local: Optional[bool] = None, exclude: Optional[List[str]] = None) -> Optional[str]:
        """Select an eligible model while honoring an explicit local preference.

        ``None`` preserves the router's configured default; ``False`` is an
        explicit request to allow external providers such as Groq.
        """
        local_preference = self._prefer_local if force_local is None else force_local
        exclude_set = set(exclude or [])
        candidates = [(key, cfg) for key, cfg in self._models.items() if key not in exclude_set and self._registry_eligible(key, cfg) and _score_model(cfg, capability, budget_tokens) != float("-inf")]
        registered = [(key, cfg) for key, cfg in candidates if key in self._provider_registry]
        if registered:
            candidates = registered
        if local_preference:
            local = [(key, cfg) for key, cfg in candidates if cfg.is_local]
            if local:
                candidates = local
        if not candidates:
            return None
        return max(candidates, key=lambda pair: _score_model(pair[1], capability, budget_tokens, local_preference))[0]

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
            if cfg.api_key == "env:OPENAI_API_KEY":
                api_key = os.getenv("OPENAI_API_KEY")
            elif cfg.api_key == "env:GROQ_API_KEY":
                api_key = os.getenv("GROQ_API_KEY")
            else:
                api_key = cfg.api_key
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
            if not self._registry_eligible(key, cfg):
                last_error = "Model artifact is not approved for runtime"
                self._record_routing(key, capability, 0.0, False)
                if forced_key:
                    break
                key = self.select_model(capability, budget_tokens, force_local=local_preference, exclude=tried)
                continue
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
                # A registered provider is an authoritative route. Do not hide
                # its failure by silently switching to another model.
                if forced_key or key in self._provider_registry:
                    break
                key = self.select_model(capability, budget_tokens, force_local=local_preference, exclude=tried)
        return RouteResult(tried[-1] if tried else "none", "none", 0.0, 0, "", False, last_error, {"fail_closed": True, "tried": tried})

    async def stream(self, messages: List[Dict[str, str]], capability: str = "general", budget_tokens: int = 4096, force_model: Optional[str] = None, timeout: float = 60.0, prefer_local: Optional[bool] = None, request_id: Optional[str] = None) -> AsyncGenerator[LLMStreamChunk, None]:
        """Relay a provider-native stream without synthesizing chunks."""
        started = time.perf_counter()
        local_preference = self._prefer_local if prefer_local is None else prefer_local
        key = self._resolve_key(force_model) if force_model else self.select_model(capability, budget_tokens, force_local=local_preference)
        if force_model and key is None:
            raise RuntimeError("Requested model is not registered")
        if key is None:
            raise RuntimeError("No eligible model is registered")
        cfg = self._models[key]
        if not self._registry_eligible(key, cfg):
            raise RuntimeError("model artifact is not approved for runtime")
        provider = await asyncio.wait_for(self._get_provider(key, cfg), timeout=timeout)
        request = self._request(messages, cfg, budget_tokens, request_id=request_id, stream=True)
        if not hasattr(provider, "stream"):
            raise RuntimeError(f"Provider {cfg.provider!r} does not expose native streaming")

        stream = provider.stream(request)
        sequence = 0
        completed = False
        try:
            yield LLMStreamChunk(
                delta="",
                index=sequence,
                model=cfg.model_id,
                provider=cfg.provider,
                request_id=request_id,
                event_type="start",
                metadata={"model": cfg.model_id, "provider": cfg.provider},
            )
            async for raw_chunk in self._iter_stream_with_timeout(stream, timeout):
                if not isinstance(raw_chunk, LLMStreamChunk):
                    raise RuntimeError("Provider returned an invalid stream chunk")
                sequence += 1
                event_type = "finish" if raw_chunk.finish_reason else (raw_chunk.event_type or "delta")
                yield LLMStreamChunk(
                    delta=raw_chunk.delta,
                    finish_reason=raw_chunk.finish_reason,
                    index=sequence,
                    model=raw_chunk.model or cfg.model_id,
                    event_type=event_type,
                    provider=raw_chunk.provider or cfg.provider,
                    request_id=raw_chunk.request_id or request_id,
                    metadata=dict(raw_chunk.metadata),
                )
                if raw_chunk.finish_reason:
                    completed = True
            if not completed:
                sequence += 1
                yield LLMStreamChunk(
                    delta="",
                    finish_reason="stop",
                    index=sequence,
                    model=cfg.model_id,
                    provider=cfg.provider,
                    request_id=request_id,
                    event_type="finish",
                    metadata={"latency_ms": (time.perf_counter() - started) * 1000},
                )
            self._record_routing(key, capability, (time.perf_counter() - started) * 1000, True)
        except asyncio.CancelledError:
            self._record_routing(key, capability, (time.perf_counter() - started) * 1000, False)
            raise
        except Exception:
            self._record_routing(key, capability, (time.perf_counter() - started) * 1000, False)
            raise
        finally:
            close = getattr(stream, "aclose", None)
            if close is not None:
                await close()

    @staticmethod
    async def _iter_stream_with_timeout(stream: Any, timeout: float) -> AsyncGenerator[LLMStreamChunk, None]:
        """Apply an idle/total guard while preserving provider-native chunks."""
        iterator = stream.__aiter__()
        try:
            while True:
                try:
                    chunk = await asyncio.wait_for(iterator.__anext__(), timeout=timeout)
                except StopAsyncIteration:
                    break
                yield chunk
        finally:
            close = getattr(iterator, "aclose", None)
            if close is not None:
                await close()

    async def list_available_models(self, capability: str = "general", budget_tokens: int = 4096) -> List[Dict[str, Any]]:
        result = []
        for key, cfg in self._models.items():
            entry = {"key": key, "model_id": cfg.model_id, "provider": cfg.provider, "capabilities": cfg.capabilities, "context_limit": cfg.context_limit, "max_tokens": cfg.max_tokens, "is_local": cfg.is_local, "available": key in self._provider_registry, "registry_eligible": self._registry_eligible(key, cfg)}
            artifact_records = [item for item in self._model_registry.list_artifacts() if item.get("model_id") in {key, cfg.model_id}]
            if artifact_records:
                entry["artifacts"] = artifact_records
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
