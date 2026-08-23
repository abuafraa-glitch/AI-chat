"""Canonical configuration contract for the local Hajeen research model.

This module restores the historical import path used by the existing model
code. It contains configuration only; it never downloads weights or starts
training.
"""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass, fields
from typing import Any, Dict, Optional


@dataclass
class HajeenConfig:
    model_name: str = "hajeen"
    vocab_size: int = 32_000
    d_model: int = 512
    d_ff: int = 2_048
    n_layers: int = 6
    n_heads: int = 8
    n_kv_heads: Optional[int] = None
    max_seq_len: int = 2_048
    dropout: float = 0.0
    attention_dropout: float = 0.0
    norm_type: str = "rmsnorm"
    pos_encoding: str = "rope"
    activation: str = "gelu"
    bias: bool = False
    norm_eps: float = 1e-5
    initializer_range: float = 0.02
    pad_token_id: int = 0
    bos_token_id: Optional[int] = None
    eos_token_id: int = 1
    rope_theta: float = 10_000.0
    use_gated_ff: bool = False

    @property
    def head_dim(self) -> int:
        return self.d_model // self.n_heads

    @property
    def effective_kv_heads(self) -> int:
        return self.n_heads if self.n_kv_heads is None else self.n_kv_heads

    def validate(self) -> None:
        if self.d_model <= 0 or self.n_layers <= 0 or self.vocab_size <= 0:
            raise ValueError("model dimensions must be positive")
        if self.n_heads <= 0 or self.d_model % self.n_heads:
            raise ValueError("d_model (" + str(self.d_model) + ") must be divisible by n_heads (" + str(self.n_heads) + ")")
        if self.n_kv_heads is not None and (
            self.n_kv_heads <= 0 or self.n_heads % self.n_kv_heads
        ):
            raise ValueError("n_heads (" + str(self.n_heads) + ") must be divisible by n_kv_heads (" + str(self.n_kv_heads) + ")")
        if self.norm_type not in {"rmsnorm", "layernorm"}:
            raise ValueError(f"Unknown norm_type: {self.norm_type}")
        if self.pos_encoding not in {"rope", "learned", "sinusoidal"}:
            raise ValueError(f"Unknown pos_encoding: {self.pos_encoding}")
        if self.activation not in {"gelu", "relu"}:
            raise ValueError(f"Unknown activation: {self.activation}")

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    def to_json(self, path: str) -> None:
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(self.to_dict(), handle, indent=2, ensure_ascii=False)

    @classmethod
    def from_dict(cls, values: Dict[str, Any]) -> "HajeenConfig":
        known = {field.name for field in fields(cls)}
        return cls(**{key: value for key, value in values.items() if key in known})

    @classmethod
    def from_json(cls, path: str) -> "HajeenConfig":
        with open(path, encoding="utf-8") as handle:
            return cls.from_dict(json.load(handle))

    @classmethod
    def from_preset(cls, preset: str) -> "HajeenConfig":
        presets = {
            "100M": dict(model_name="hajeen-100m", d_model=512, n_layers=12, n_heads=8),
            "300M": dict(model_name="hajeen-300m", d_model=768, n_layers=16, n_heads=12),
            "1B": dict(model_name="hajeen-1b", d_model=2_048, n_layers=24, n_heads=16),
            "3B": dict(model_name="hajeen-3b", d_model=3_072, n_layers=32, n_heads=24),
            "7B": dict(model_name="hajeen-7b", d_model=4_096, n_layers=32, n_heads=32, n_kv_heads=8),
            "13B": dict(model_name="hajeen-13b", d_model=5_120, n_layers=40, n_heads=40, n_kv_heads=8),
            "70B": dict(model_name="hajeen-70b", d_model=8_192, n_layers=80, n_heads=64, n_kv_heads=8),
        }
        if preset not in presets:
            raise ValueError(f"Unknown preset '{preset}'. Choose from: {list(presets)}")
        config = cls(**presets[preset])
        config.validate()
        return config
