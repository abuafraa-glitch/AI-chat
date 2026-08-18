"""Deprecated compatibility facade for the pre-Phase-7 evolution API.

All proposal, evaluation, experiment, approval, and mutation authority now
belongs to :mod:`brain.evolution.phase7_lifecycle`.  This module deliberately
fails closed so an old caller cannot bypass evidence, isolation, evaluation,
approval, versioning, staging, or rollback gates.
"""
from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .phase7_lifecycle import EvolutionLifecycleError
from ..reflection.self_reflection import ReflectionReport


@dataclass
class EvolutionProposal:
    """Legacy data shape retained for callers that only serialize proposals."""

    proposal_id: str
    source_report_id: str
    type: str
    description: str
    proposed_change: Dict[str, Any]
    status: str = "pending"
    created_at: float = field(default_factory=time.time)
    evaluated_at: Optional[float] = None
    implemented_at: Optional[float] = None
    evaluation_result: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "proposal_id": self.proposal_id,
            "source_report_id": self.source_report_id,
            "type": self.type,
            "description": self.description,
            "proposed_change": self.proposed_change,
            "status": self.status,
            "created_at": self.created_at,
            "evaluated_at": self.evaluated_at,
            "evaluation_result": self.evaluation_result,
            "implemented_at": self.implemented_at,
        }


class SelfEvolution:
    """Fail-closed facade; use ``EvolutionLifecycle`` for all real operations."""

    def __init__(self, storage_path: str = "storage_data/brain/evolution") -> None:
        self.storage_path = storage_path
        self._proposals: List[EvolutionProposal] = []

    async def initialize(self) -> None:
        """Retained as a no-op for startup compatibility; no authority is built."""
        return None

    async def analyze_and_propose_async(self, report: ReflectionReport) -> str:
        raise EvolutionLifecycleError("legacy_evolution_path_disabled")

    async def analyze_and_propose(self, report: ReflectionReport) -> Optional[EvolutionProposal]:
        raise EvolutionLifecycleError("legacy_evolution_path_disabled")

    async def evaluate_and_implement_async(self, proposal: EvolutionProposal) -> str:
        raise EvolutionLifecycleError("legacy_evolution_path_disabled")

    async def evaluate_and_implement(self, proposal: EvolutionProposal) -> bool:
        raise EvolutionLifecycleError("legacy_evolution_path_disabled")

    async def _implement_change(self, change_type: str, change_data: Dict[str, Any]) -> bool:
        raise EvolutionLifecycleError("legacy_production_mutation_disabled")

    def get_pending_proposals(self) -> List[EvolutionProposal]:
        return [proposal for proposal in self._proposals if proposal.status == "pending"]


_evolution_engine: Optional[SelfEvolution] = None


async def get_self_evolution_engine() -> SelfEvolution:
    """Return the compatibility facade, never a mutable evolution authority."""
    global _evolution_engine
    if _evolution_engine is None:
        _evolution_engine = SelfEvolution()
    return _evolution_engine


__all__ = ["EvolutionProposal", "SelfEvolution", "get_self_evolution_engine"]
