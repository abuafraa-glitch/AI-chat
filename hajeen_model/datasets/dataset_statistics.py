"""Deterministic statistics for dataset readiness evidence."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence


@dataclass
class DatasetStatistics:
    total_sequences: int = 0
    total_tokens: int = 0
    avg_seq_len: float = 0.0

    def compute(self, sequences: Iterable[Sequence[int]]) -> "DatasetStatistics":
        rows = list(sequences)
        self.total_sequences = len(rows)
        self.total_tokens = sum(len(row) for row in rows)
        self.avg_seq_len = self.total_tokens / self.total_sequences if rows else 0.0
        return self

    def to_dict(self):
        return {"total_sequences": self.total_sequences, "total_tokens": self.total_tokens, "avg_seq_len": self.avg_seq_len}

    def estimated_gpu_hours(self, tokens_per_second_per_gpu: float = 1_000.0) -> float:
        if tokens_per_second_per_gpu <= 0:
            raise ValueError("tokens_per_second_per_gpu must be positive")
        return self.total_tokens / tokens_per_second_per_gpu / 3600.0
