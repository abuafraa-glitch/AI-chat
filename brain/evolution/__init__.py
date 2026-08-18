"""
brain/evolution/ — Compatibility shim for SelfEvolution
========================================================
All evolution logic now lives in brain/reflection/self_evolution.py
This module re-exports from there for backward compatibility.

DEPRECATED: Use brain.reflection.self_evolution directly.
"""

from __future__ import annotations

import warnings

# Re-export everything from the unified implementation
from .phase7_lifecycle import (
    EvolutionHypothesis,
    EvolutionLifecycle,
    EvolutionLifecycleCoordinator,
    EvolutionLifecycleError,
    EvolutionObservation,
    EvolutionRecord,
    EvolutionState,
    EvolutionTrace,
    ExperimentResult,
    make_phase6_evaluator,
)
from brain.reflection.self_evolution import (
    EvolutionStatus,
    EvolutionTarget,
    get_self_evolution,
)
from .self_evolution import EvolutionProposal, SelfEvolution, get_self_evolution_engine


__all__ = [
    "EvolutionProposal",
    "EvolutionStatus", 
    "EvolutionTarget",
    "SelfEvolution",
    "get_self_evolution",
    "get_self_evolution_engine",  # legacy alias
    "EvolutionLifecycle",
    "EvolutionLifecycleCoordinator",
    "EvolutionLifecycleError",
    "EvolutionObservation",
    "EvolutionHypothesis",
    "ExperimentResult",
    "EvolutionRecord",
    "EvolutionState",
    "EvolutionTrace",
    "make_phase6_evaluator",
]

warnings.warn(
    "brain.evolution is deprecated. Use brain.reflection directly.",
    DeprecationWarning,
    stacklevel=2,
)
