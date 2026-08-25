from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterator, Optional

import torch

from .base_provider import BaseProvider
from .ollama_provider import OllamaProvider
from .hajeen_provider import HajeenProvider


@dataclass
class GenerationConfig:
    do_sample: bool = True
    temperature: float = 1.0
    top_k: int = 0
    top_p: float = 1.0
    max_new_tokens: int = 256


class InferenceEngine:
    """Compatibility engine for provider mode and local causal-model mode."""

    def __init__(self, provider_or_model: Any = "ollama", tokenizer=None, device: str = "cpu", provider_type: Optional[str] = None, **kwargs):
        self.model = None
        self.tokenizer = tokenizer
        self.device = torch.device(device)
        if not isinstance(provider_or_model, str):
            self.model = provider_or_model.to(self.device).eval()
            self.current_provider_name = "hajeen-local"
            self.provider = None
            return
        selected = provider_type or provider_or_model
        self.providers = {"ollama": OllamaProvider, "hajeen": HajeenProvider}
        self.current_provider_name = selected
        self.provider = self._create_provider(selected, **kwargs)

    def _create_provider(self, provider_type: str, **kwargs) -> BaseProvider:
        provider_class = self.providers.get(provider_type.lower())
        if not provider_class:
            raise ValueError(f"Unknown provider type: {provider_type}")
        return provider_class(**kwargs)

    def switch_provider(self, provider_type: str, **kwargs):
        self.provider = self._create_provider(provider_type, **kwargs)
        self.current_provider_name = provider_type

    def infer(self, prompt: str, **kwargs) -> str:
        if self.model is not None:
            return self.generate(prompt, kwargs.get("generation_config"))
        try:
            return self.provider.generate(prompt, **kwargs)
        except Exception as exc:
            return f"Inference Error ({self.current_provider_name}): {exc}"

    def get_status(self) -> dict:
        if self.model is not None:
            return {"provider": "hajeen-local", "model": self.model.__class__.__name__, "engine_active_provider": self.current_provider_name}
        status = self.provider.get_model_info()
        status["engine_active_provider"] = self.current_provider_name
        return status

    def _config(self, config=None) -> GenerationConfig:
        return config if isinstance(config, GenerationConfig) else GenerationConfig()

    @torch.no_grad()
    def generate(self, prompt: str, config: Optional[GenerationConfig] = None) -> str:
        if self.model is None or self.tokenizer is None:
            raise RuntimeError("local generation requires a model and tokenizer")
        cfg = self._config(config)
        ids = self.tokenizer.encode(prompt, return_tensors="pt").to(self.device)
        limit = min(cfg.max_new_tokens, max(0, int(getattr(self.model.config, "max_seq_len", 4096)) - ids.shape[1]))
        for _ in range(limit):
            logits = self.model(ids)["logits"][:, -1, :]
            if cfg.do_sample:
                temperature = max(float(cfg.temperature), 1e-5)
                logits = logits / temperature
                if cfg.top_k > 0:
                    values, _ = torch.topk(logits, min(cfg.top_k, logits.shape[-1]))
                    logits[logits < values[:, [-1]]] = -float("inf")
                if cfg.top_p < 1.0:
                    sorted_logits, sorted_indices = torch.sort(logits, descending=True)
                    cumulative = torch.softmax(sorted_logits, dim=-1).cumsum(dim=-1)
                    remove = cumulative - torch.softmax(sorted_logits, dim=-1) > cfg.top_p
                    sorted_logits[remove] = -float("inf")
                    logits = torch.zeros_like(logits).scatter(1, sorted_indices, sorted_logits)
                next_id = torch.multinomial(torch.softmax(logits, dim=-1), 1)
            else:
                next_id = logits.argmax(dim=-1, keepdim=True)
            ids = torch.cat([ids, next_id], dim=1)
            if int(next_id.item()) == int(self.tokenizer.eos_token_id):
                break
        return self.tokenizer.decode(ids[:, ids.shape[1] - limit:] if limit else ids, skip_special_tokens=True)

    def stream(self, prompt: str, config: Optional[GenerationConfig] = None) -> Iterator[str]:
        text = self.generate(prompt, config)
        for token in text.split():
            yield token

    def generate_batch(self, prompts: list[str], config: Optional[GenerationConfig] = None) -> list[str]:
        return [self.generate(prompt, config) for prompt in prompts]
