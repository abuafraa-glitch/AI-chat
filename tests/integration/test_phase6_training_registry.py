from __future__ import annotations

import json

import pytest

from brain.learning.phase6_lifecycle import (
    EvaluationPipelineLifecycle,
    EvaluationStatus,
    TrainingPipelineLifecycle,
    TrainingStatus,
)
from core.model.model_registry import ModelArtifactRecord, ModelArtifactStatus, ModelRegistry


def test_training_gate_blocks_missing_dataset(tmp_path):
    lifecycle = TrainingPipelineLifecycle(storage_dir=str(tmp_path / "runs"))
    run = lifecycle.create_run(
        dataset_id="ds",
        dataset_version="v1",
        dataset_path=str(tmp_path / "missing.jsonl"),
        base_model="base",
        base_model_version="1",
    )
    assert run.status is TrainingStatus.BLOCKED
    assert run.error == "dataset_missing"


def test_training_cannot_complete_with_invalid_artifact(tmp_path):
    dataset = tmp_path / "dataset.jsonl"
    dataset.write_text(json.dumps({"text": "real record"}) + "\n", encoding="utf-8")
    lifecycle = TrainingPipelineLifecycle(storage_dir=str(tmp_path / "runs"))
    run = lifecycle.create_run(
        dataset_id="ds",
        dataset_version="v1",
        dataset_path=str(dataset),
        base_model="base",
        base_model_version="1",
    )
    assert run.status is TrainingStatus.QUEUED
    lifecycle.start(run)
    lifecycle.complete(run, str(tmp_path / "not-a-model"), {"loss": 0.1})
    assert run.status is TrainingStatus.FAILED
    assert run.artifact_location == ""
    assert "artifact_invalid" in run.error


def test_evaluation_gate_blocks_missing_or_incompatible_artifact(tmp_path):
    lifecycle = EvaluationPipelineLifecycle(storage_dir=str(tmp_path / "eval"))
    run = lifecycle.create_run(
        model_id="m",
        model_version="v1",
        artifact_location=str(tmp_path / "missing"),
        benchmark_id="bench",
        benchmark_version="v1",
        sample_count=10,
    )
    assert run.status is EvaluationStatus.BLOCKED
    assert "artifact_invalid" in run.error


def test_evaluation_does_not_run_when_blocked(tmp_path):
    lifecycle = EvaluationPipelineLifecycle(storage_dir=str(tmp_path / "eval"))
    run = lifecycle.create_run(
        model_id="m",
        model_version="v1",
        artifact_location=str(tmp_path / "missing"),
        benchmark_id="bench",
        benchmark_version="v1",
        sample_count=10,
    )
    lifecycle.run(run, lambda: {"accuracy": 1.0}, thresholds={"accuracy": 0.9})
    assert run.status is EvaluationStatus.BLOCKED
    assert run.metrics == {}


def test_registry_requires_evaluation_before_approval(tmp_path):
    registry = ModelRegistry()
    artifact_dir = tmp_path / "artifact"
    artifact_dir.mkdir()
    model_id = "phase6-test-model"
    version = "v1"
    record = ModelArtifactRecord(
        model_id=model_id,
        model_version=version,
        model_type="causal_lm",
        artifact_location=str(artifact_dir),
        base_model="base",
        dataset_version="ds-v1",
        training_run_id="train-1",
    )
    registry.register_artifact(record)
    with pytest.raises(ValueError, match="evaluated"):
        registry.approve(model_id, version)
    registry.mark_evaluated(model_id, version, "eval-1", {"accuracy": 0.95}, True)
    registry.approve(model_id, version)
    registry.promote(model_id, version, ModelArtifactStatus.STAGING)
    assert registry.get_artifact(model_id, version).status is ModelArtifactStatus.STAGING


def test_registry_rejects_failed_evaluation_and_no_promotion(tmp_path):
    registry = ModelRegistry()
    artifact_dir = tmp_path / "artifact"
    artifact_dir.mkdir()
    model_id = "phase6-rejected-model"
    version = "v1"
    registry.register_artifact(ModelArtifactRecord(
        model_id=model_id,
        model_version=version,
        model_type="causal_lm",
        artifact_location=str(artifact_dir),
        base_model="base",
        dataset_version="ds-v1",
        training_run_id="train-2",
    ))
    registry.mark_evaluated(model_id, version, "eval-2", {"accuracy": 0.2}, False)
    with pytest.raises(ValueError, match="APPROVED"):
        registry.promote(model_id, version, ModelArtifactStatus.PRODUCTION)
    assert registry.get_artifact(model_id, version).status is ModelArtifactStatus.REJECTED


@pytest.mark.asyncio
async def test_model_router_excludes_unapproved_registered_artifact(tmp_path):
    from brain.model_router import ModelConfig, ModelRouter

    registry = ModelRegistry()
    model_id = "phase6-router-guard"
    artifact_dir = tmp_path / "artifact"
    artifact_dir.mkdir()
    registry.register_artifact(ModelArtifactRecord(
        model_id=model_id,
        model_version="v1",
        model_type="causal_lm",
        artifact_location=str(artifact_dir),
        base_model="base",
        dataset_version="ds-v1",
        training_run_id="train-router",
        status=ModelArtifactStatus.TRAINED,
    ))
    registry.reject(model_id, "v1", "test_rejection")
    router = ModelRouter(prefer_local=False, model_registry=registry)
    router.add_model("phase6-router-key", ModelConfig(
        model_id=model_id,
        provider="test",
        base_url=None,
        api_key=None,
        capabilities=["phase6-router"],
        context_limit=128,
        max_tokens=32,
        avg_latency_ms=1,
        cost_per_1k_tokens=0,
        quality_score=1,
        is_local=False,
    ))
    assert router.select_model("phase6-router", 8) is None
    result = await router.route([], capability="phase6-router", budget_tokens=8, force_model="phase6-router-key")
    assert result.success is False
    assert result.metadata["fail_closed"] is True
    assert "approved" in result.error.lower()
