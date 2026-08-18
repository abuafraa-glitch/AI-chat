from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

WEIGHT_NAMES = ("model.safetensors", "pytorch_model.bin", "pytorch_model.bin.index.json")
TOKENIZER_NAMES = ("tokenizer.json", "tokenizer.model", "tokenizer_config.json")


def validate_artifact_directory(location: str) -> tuple[bool, tuple[str, ...], str, dict[str, Any]]:
    root = Path(location)
    reasons: list[str] = []
    if not root.is_dir():
        return False, ("artifact_directory_missing",), "", {}
    config_path = root / "config.json"
    config: dict[str, Any] = {}
    if not config_path.is_file():
        reasons.append("config_missing")
    else:
        try:
            config = json.loads(config_path.read_text(encoding="utf-8"))
            if not isinstance(config, dict):
                reasons.append("config_invalid")
                config = {}
        except (OSError, UnicodeError, json.JSONDecodeError):
            reasons.append("config_invalid")
    if not any((root / name).is_file() for name in WEIGHT_NAMES):
        reasons.append("weights_missing")
    if not any((root / name).is_file() for name in TOKENIZER_NAMES):
        reasons.append("tokenizer_missing")
    architectures = config.get("architectures", [])
    if architectures and not any("CausalLM" in str(item) for item in architectures):
        reasons.append("incompatible_model_architecture")
    if not config.get("model_type"):
        reasons.append("model_type_missing")
    checksum = ""
    if not reasons:
        digest = hashlib.sha256()
        for path in sorted(p for p in root.rglob("*") if p.is_file()):
            digest.update(str(path.relative_to(root)).encode())
            digest.update(path.read_bytes())
        checksum = digest.hexdigest()
    return not reasons, tuple(reasons), checksum, {
        "model_type": config.get("model_type", ""),
        "architectures": architectures,
    }
