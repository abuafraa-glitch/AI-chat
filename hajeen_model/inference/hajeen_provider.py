from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

from .base_provider import BaseProvider

logger = logging.getLogger(__name__)


class HajeenProvider(BaseProvider):
    """Local Hajeen provider.

    This provider never fabricates output.  A successful provider state requires
    a real Transformers-compatible checkpoint and a successful load of both the
    tokenizer and model.  Missing or invalid resources fail closed.
    """

    def __init__(self, model_path: str | None = None, device: str = "auto"):
        self.model_path = model_path or os.getenv(
            "HAJEEN_MODEL_PATH", "hajeen_model/checkpoints/final"
        )
        self.device = device
        self.model: Any = None
        self.tokenizer: Any = None
        self._is_loaded = False
        self._load_error: str | None = None

    def _checkpoint_files_present(self, path: Path) -> bool:
        if not path.is_dir() or not (path / "config.json").is_file():
            return False
        tokenizer_present = any(
            (path / name).is_file()
            for name in ("tokenizer.json", "tokenizer_config.json", "spiece.model", "vocab.json")
        )
        weights_present = any(
            candidate.is_file()
            for pattern in ("*.safetensors", "pytorch_model*.bin", "*.bin", "*.pt", "*.pth")
            for candidate in path.glob(pattern)
        )
        return tokenizer_present and weights_present

    def load_model(self) -> bool:
        if self._is_loaded:
            return True

        path = Path(self.model_path)
        if not self._checkpoint_files_present(path):
            self._load_error = (
                f"Hajeen checkpoint is unavailable or incomplete at {path}; "
                "required config, tokenizer, and model weights were not found"
            )
            logger.error(self._load_error)
            return False

        try:
            from transformers import AutoModelForCausalLM, AutoTokenizer

            tokenizer = AutoTokenizer.from_pretrained(str(path), local_files_only=True)
            model_kwargs: dict[str, Any] = {"local_files_only": True}
            if self.device != "auto":
                model_kwargs["device_map"] = self.device
            model = AutoModelForCausalLM.from_pretrained(str(path), **model_kwargs)
            if self.device != "auto" and "device_map" not in model_kwargs:
                model.to(self.device)
            self.tokenizer = tokenizer
            self.model = model
            self._is_loaded = True
            self._load_error = None
            logger.info("Hajeen model loaded successfully from %s", path)
            return True
        except Exception as exc:
            self.model = None
            self.tokenizer = None
            self._is_loaded = False
            self._load_error = f"Hajeen checkpoint load failed: {exc}"
            logger.exception(self._load_error)
            return False

    def generate(self, prompt: str, **kwargs: Any) -> str:
        if not self.load_model():
            raise RuntimeError(self._load_error or "Hajeen model is unavailable")
        if not prompt:
            raise ValueError("prompt must not be empty")

        inputs = self.tokenizer(prompt, return_tensors="pt")
        if self.device != "auto":
            inputs = {key: value.to(self.device) for key, value in inputs.items()}
        output_ids = self.model.generate(**inputs, **kwargs)
        return self.tokenizer.decode(output_ids[0], skip_special_tokens=True)

    def get_model_info(self) -> dict[str, Any]:
        return {
            "provider": "HajeenLocal",
            "model_path": self.model_path,
            "device": self.device,
            "is_loaded": self._is_loaded,
            "available": self._is_loaded,
            "load_error": self._load_error,
        }
