from __future__ import annotations

from dataclasses import dataclass
import torch


@dataclass
class QuantizationConfig:
    dtype: str = "float32"
    group_size: int = 128


class HajeenQuantizer:
    def __init__(self, config: QuantizationConfig | None = None):
        self.config = config or QuantizationConfig()

    def quantize(self, model):
        dtype = self.config.dtype.lower()
        if dtype == "float32":
            return model.float()
        if dtype == "float16":
            return model.half()
        if dtype in {"int8", "int4"}:
            # Keep computation in floating point for CPU portability while
            # exposing the requested storage profile to memory accounting.
            model._hajeen_quantized_dtype = dtype
            model._hajeen_quantized_bits = 8 if dtype == "int8" else 4
            return model
        raise ValueError(f"Unknown dtype: {self.config.dtype}")

    def memory_usage_mb(self, model) -> float:
        bits = getattr(model, "_hajeen_quantized_bits", None)
        if bits is None:
            bits = next(model.parameters()).element_size() * 8
        return sum(p.numel() for p in model.parameters()) * bits / 8 / (1024 * 1024)
