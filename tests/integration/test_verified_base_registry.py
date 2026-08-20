import json
from pathlib import Path

from brain.model_router import ModelRouter, VERIFIED_BASE_TARGET_COMMIT
from core.model.artifact_validation import load_verified_base_manifest, validate_artifact_directory
from core.model.model_registry import ModelArtifactStatus, ModelRegistry


def _artifact(tmp_path: Path) -> Path:
    root = tmp_path / "qwen3"
    root.mkdir()
    (root / "config.json").write_text(json.dumps({"model_type": "qwen3", "architectures": ["Qwen3ForCausalLM"]}), encoding="utf-8")
    (root / "tokenizer.json").write_text("{}", encoding="utf-8")
    (root / "model.safetensors.index.json").write_text("{}", encoding="utf-8")
    (root / "model-00001-of-00016.safetensors").write_bytes(b"test-shard")
    (root / "hajeen_verified_base_manifest.json").write_text(json.dumps({
        "status": "VERIFIED_BASE",
        "source_model_id": "Qwen/Qwen3-30B-A3B",
        "source_revision": "ad44e777bcd18fa416d9da3bd8f70d33ebb85d39",
        "target_repo_id": "Raedthawaba/hajeen-base-qwen3-30b-a3b",
        "target_commit": VERIFIED_BASE_TARGET_COMMIT,
        "artifact_verification": {"all_shard_sha256_match": True},
        "tokenizer_verification": {"encode_decode_round_trip_passed": True},
    }), encoding="utf-8")
    return root


def test_verified_manifest_and_sharded_artifact(tmp_path):
    root = _artifact(tmp_path)
    valid, reasons, _, metadata = validate_artifact_directory(str(root))
    assert valid, reasons
    assert metadata["shard_count"] == 1
    manifest_valid, manifest_reasons, manifest = load_verified_base_manifest(str(root))
    assert manifest_valid, manifest_reasons
    assert manifest["target_commit"] == VERIFIED_BASE_TARGET_COMMIT


def test_registry_registers_verified_base_idempotently(tmp_path):
    root = _artifact(tmp_path)
    registry = ModelRegistry()
    registry._artifacts.clear()
    first = registry.register_verified_base(str(root), "hajeen-base", "qwen3-30b-a3b")
    second = registry.register_verified_base(str(root), "hajeen-base", "qwen3-30b-a3b")
    assert first is second
    assert first.status is ModelArtifactStatus.VERIFIED_BASE
    assert first.lineage["target_commit"] == VERIFIED_BASE_TARGET_COMMIT


def test_router_rejects_unregistered_hajeen_local():
    registry = ModelRegistry()
    registry._artifacts.clear()
    router = ModelRouter(prefer_local=True, model_registry=registry)
    assert router.select_model() != "hajeen-local"
