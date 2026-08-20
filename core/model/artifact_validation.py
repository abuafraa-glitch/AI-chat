from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

WEIGHT_NAMES = ("model.safetensors", "pytorch_model.bin", "pytorch_model.bin.index.json")
TOKENIZER_NAMES = ("tokenizer.json", "tokenizer.model", "tokenizer_config.json")
MANIFEST_NAMES = ("hajeen_verified_base_manifest.json", "base_model_contract.json")


def _shard_files(root: Path) -> list[Path]:
    return sorted(root.glob("model-*.safetensors"))


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

    shards = _shard_files(root)
    index_path = root / "model.safetensors.index.json"
    has_weights = any((root / name).is_file() for name in WEIGHT_NAMES) or bool(shards and index_path.is_file())
    if not has_weights:
        reasons.append("weights_missing")
    if not any((root / name).is_file() for name in TOKENIZER_NAMES):
        reasons.append("tokenizer_missing")
    architectures = config.get("architectures", [])
    if architectures and not any("CausalLM" in str(item) for item in architectures):
        reasons.append("incompatible_model_architecture")
    if not config.get("model_type"):
        reasons.append("model_type_missing")

    manifest_path = next((root / name for name in MANIFEST_NAMES if (root / name).is_file()), root / MANIFEST_NAMES[0])
    manifest: dict[str, Any] = {}
    if manifest_path.is_file():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            if manifest.get("status") == "VERIFIED_BASE":
                required = ("source_model_id", "source_revision", "target_repo_id", "target_commit")
                for field in required:
                    if not manifest.get(field):
                        reasons.append(f"manifest_{field}_missing")
        except (OSError, UnicodeError, json.JSONDecodeError):
            reasons.append("manifest_invalid")

    checksum = ""
    if not reasons:
        digest = hashlib.sha256()
        for path in sorted(p for p in root.rglob("*") if p.is_file() and p != manifest_path):
            digest.update(str(path.relative_to(root)).encode())
            digest.update(path.read_bytes())
        checksum = digest.hexdigest()

    return not reasons, tuple(reasons), checksum, {
        "model_type": config.get("model_type", ""),
        "architectures": architectures,
        "shard_count": len(shards),
        "has_safetensors_index": index_path.is_file(),
        "verification_manifest": manifest,
    }


def load_verified_base_manifest(location: str) -> tuple[bool, tuple[str, ...], dict[str, Any]]:
    root = Path(location)
    path = next((root / name for name in MANIFEST_NAMES if (root / name).is_file()), root / MANIFEST_NAMES[0])
    if not path.is_file():
        return False, ("verification_manifest_missing",), {}
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return False, ("verification_manifest_invalid",), {}
    required = ("source_model_id", "source_revision", "target_repo_id", "target_commit")
    reasons = [f"manifest_{field}_missing" for field in required if not manifest.get(field)]
    if manifest.get("status") != "VERIFIED_BASE":
        reasons.append("manifest_status_not_verified_base")
    artifact = manifest.get("artifact_verification", {})
    tokenizer = manifest.get("tokenizer_verification", {})
    if artifact.get("all_shard_sha256_match") is not True:
        reasons.append("manifest_shard_verification_failed")
    if tokenizer.get("encode_decode_round_trip_passed") is not True:
        reasons.append("manifest_tokenizer_verification_failed")
    return not reasons, tuple(reasons), manifest
