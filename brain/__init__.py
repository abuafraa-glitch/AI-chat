"""Public lazy exports for the Hajeen Brain package."""
from __future__ import annotations

from importlib import import_module

__all__ = [
    "HajeenBrain",
    "HajeenBrainV3",
    "BrainRequest",
    "BrainResponse",
    "get_brain",
    "get_brain_v3",
]


def __getattr__(name: str):
    if name in __all__:
        module = import_module("brain.brain_v3")
        if name == "HajeenBrain":
            return module.HajeenBrainV3
        return getattr(module, name)
    raise AttributeError(name)
