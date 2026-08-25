"""Registry for real LLM provider adapters.

Test doubles may be registered explicitly by tests, but are never auto-registered
in the production registry.
"""
from __future__ import annotations

import importlib
import logging
from typing import Dict, List, Optional, Type

from .base import BaseLLMProvider, LLMConfig

logger = logging.getLogger(__name__)


class ProviderRegistry:
    _providers: Dict[str, Type[BaseLLMProvider]] = {}
    _aliases: Dict[str, str] = {}

    @classmethod
    def register(cls, name: str, provider_class: Type[BaseLLMProvider], aliases: Optional[List[str]] = None) -> None:
        cls._providers[name.lower()] = provider_class
        for alias in aliases or []:
            cls._aliases[alias.lower()] = name.lower()

    @classmethod
    def get(cls, name: str) -> Optional[Type[BaseLLMProvider]]:
        key = name.lower()
        return cls._providers.get(cls._aliases.get(key, key))

    @classmethod
    def get_or_raise(cls, name: str) -> Type[BaseLLMProvider]:
        provider = cls.get(name)
        if provider is None:
            raise KeyError(f"Provider {name!r} not found. Available: {', '.join(cls.list_providers())}")
        return provider

    @classmethod
    def create(cls, name: str, config: Optional[LLMConfig] = None) -> BaseLLMProvider:
        provider_class = cls.get_or_raise(name)
        return provider_class(config or LLMConfig(provider=name))

    @classmethod
    def list_providers(cls) -> List[str]:
        return sorted(cls._providers)

    @classmethod
    def is_registered(cls, name: str) -> bool:
        return cls.get(name) is not None

    @classmethod
    def load_from_module(cls, module_path: str, class_name: str, provider_name: str, aliases: Optional[List[str]] = None) -> bool:
        try:
            module = importlib.import_module(module_path)
            cls.register(provider_name, getattr(module, class_name), aliases)
            return True
        except (ImportError, AttributeError) as exc:
            logger.debug("Provider %s unavailable: %s", provider_name, exc)
            return False

    @classmethod
    def auto_register_defaults(cls) -> None:
        defaults = [
            ("core.llm.providers.openai_provider", "OpenAIProvider", "openai", ["gpt", "chatgpt"]),
            # Groq يستخدم واجهة OpenAI الرسمية، لذلك يعاد استخدام المحول نفسه.
            ("core.llm.providers.openai_provider", "OpenAIProvider", "groq", ["groq"]),
            ("core.llm.providers.ollama_provider", "OllamaProvider", "ollama", ["local"]),
            ("core.llm.providers.huggingface_provider", "HuggingFaceProvider", "huggingface", ["hf"]),
            ("core.llm.providers.llama_cpp_provider", "LlamaCppProvider", "llama_cpp", ["llama", "gguf"]),
            ("core.llm.providers.hajeen_provider", "HajeenLLMProvider", "hajeen", ["hajeen_local"]),
        ]
        for module_path, class_name, name, aliases in defaults:
            cls.load_from_module(module_path, class_name, name, aliases)

    @classmethod
    def clear(cls) -> None:
        cls._providers.clear()
        cls._aliases.clear()


__all__ = ["ProviderRegistry"]
