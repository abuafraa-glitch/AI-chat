from __future__ import annotations

import json

import pytest

from brain.learning.learning_lifecycle import LearningLifecycleCoordinator
from brain.learning.phase6_lifecycle import EvaluationStatus, TrainingStatus
from data_engine.lifecycle import DatasetStatus, SourceMetadata
from core.model.model_registry import ModelArtifactStatus, ModelRegistry


def records():
    return [{
        "instruction": "Explain how to preserve provenance across a real dataset lifecycle.",
        "output": "A lifecycle should retain source metadata, deterministic checksums, stage reports, and explicit approval gates.",
    }]


def test_coordinator_blocks_training_for_nonapproved_dataset(tmp_path):
    coordinator = LearningLifecycleCoordinator(
        data_engine=__import__("data_engine.lifecycle", fromlist=["DataEngine"]).DataEngine(storage_dir=str(tmp_path / "data"), supported_languages={"en"}),
        registry=ModelRegistry(),
    )
    dataset = coordinator.prepare_dataset(SourceMetadata("source", "test"), lambda: [])
    assert dataset.status is DatasetStatus.INVALID
    with pytest.raises(ValueError, match="APPROVED"):
        coordinator.queue_training(dataset, base_model="base", base_model_version="1")


def test_coordinator_blocks_evaluation_without_real_evaluator(tmp_path):
    from brain.learning.phase6_lifecycle import TrainingPipelineLifecycle
    from data_engine.lifecycle import DataEngine

    data = DataEngine(storage_dir=str(tmp_path / "data"), supported_languages={"en"})
    coordinator = LearningLifecycleCoordinator(
        data_engine=data,
        training=TrainingPipelineLifecycle(storage_dir=str(tmp_path / "training")),
        registry=ModelRegistry(),
    )
    dataset = coordinator.prepare_dataset(SourceMetadata("source-2", "test"), records)
    assert dataset.status is DatasetStatus.APPROVED
    training = coordinator.queue_training(dataset, base_model="base", base_model_version="1")
    assert training.status is TrainingStatus.QUEUED
    # No local causal checkpoint is assumed in production; the gate must fail closed.
    training.status = TrainingStatus.COMPLETED
    training.artifact_location = str(tmp_path / "missing-artifact")
    evaluation = coordinator.evaluate_training(
        training,
        model_id="m",
        model_version="v1",
        benchmark_id="b",
        benchmark_version="v1",
        sample_count=1,
        infer_and_measure=None,
    )
    assert evaluation.status is EvaluationStatus.BLOCKED


def test_coordinator_requires_passing_evaluation_before_registration(tmp_path):
    from brain.learning.phase6_lifecycle import EvaluationPipelineLifecycle, TrainingPipelineLifecycle
    from data_engine.lifecycle import DataEngine

    data = DataEngine(storage_dir=str(tmp_path / "data"), supported_languages={"en"})
    coordinator = LearningLifecycleCoordinator(
        data_engine=data,
        training=TrainingPipelineLifecycle(storage_dir=str(tmp_path / "training")),
        evaluation=EvaluationPipelineLifecycle(storage_dir=str(tmp_path / "evaluation")),
        registry=ModelRegistry(),
    )
    dataset = coordinator.prepare_dataset(SourceMetadata("source-3", "test"), records)
    training = coordinator.queue_training(dataset, base_model="base", base_model_version="1")
    training.status = TrainingStatus.COMPLETED
    training.artifact_location = str(tmp_path / "missing-artifact")
    evaluation = coordinator.evaluate_training(
        training,
        model_id="m3",
        model_version="v1",
        benchmark_id="b",
        benchmark_version="v1",
        sample_count=2,
    )
    assert evaluation.status is EvaluationStatus.BLOCKED
    with pytest.raises(ValueError, match="passing"):
        coordinator.register_and_approve(training, evaluation, model_id="m3", model_version="v1", model_type="causal_lm")


def test_coordinator_full_data_to_approved_model_lineage(tmp_path):
    from brain.learning.phase6_lifecycle import EvaluationPipelineLifecycle, TrainingPipelineLifecycle
    from data_engine.lifecycle import DataEngine

    data = DataEngine(storage_dir=str(tmp_path / "data"), supported_languages={"en"})
    coordinator = LearningLifecycleCoordinator(
        data_engine=data,
        training=TrainingPipelineLifecycle(storage_dir=str(tmp_path / "training")),
        evaluation=EvaluationPipelineLifecycle(storage_dir=str(tmp_path / "evaluation")),
        registry=ModelRegistry(),
    )
    dataset = coordinator.prepare_dataset(SourceMetadata("e2e-source", "fixture", provenance="fixture://e2e"), records)
    assert dataset.status is DatasetStatus.APPROVED
    training = coordinator.queue_training(dataset, base_model="base", base_model_version="1", code_version="test-code")
    assert training.dataset_checksum == dataset.checksum
    artifact_dir = tmp_path / "artifact"
    artifact_dir.mkdir()
    (artifact_dir / "config.json").write_text(json.dumps({"model_type": "test", "architectures": ["TestForCausalLM"]}), encoding="utf-8")
    (artifact_dir / "pytorch_model.bin").write_bytes(b"e2e-artifact")
    (artifact_dir / "tokenizer.json").write_text("{}", encoding="utf-8")
    training = coordinator.complete_training(training, artifact_location=str(artifact_dir), metrics={"loss": 0.1})
    assert training.status is TrainingStatus.COMPLETED
    benchmark = tmp_path / "benchmark.jsonl"
    benchmark.write_text('{"prompt":"hello","expected":"hi"}\n', encoding="utf-8")
    evaluation = coordinator.evaluate_training(
        training,
        model_id="e2e-model",
        model_version="v1",
        benchmark_id="e2e-benchmark",
        benchmark_version="v1",
        benchmark_path=str(benchmark),
        benchmark_source="fixture://benchmark",
        infer_and_measure=lambda: {"accuracy": 0.95},
        thresholds={"accuracy": 0.9},
    )
    assert evaluation.status is EvaluationStatus.COMPLETED
    approved = coordinator.register_and_approve(
        training, evaluation, model_id="e2e-model", model_version="v1", model_type="causal_lm"
    )
    assert approved.status is ModelArtifactStatus.APPROVED
    assert approved.dataset_checksum == dataset.checksum
    assert approved.benchmark_checksum == evaluation.benchmark_checksum
    assert approved.lineage["dataset"]["source"] == "fixture://e2e"
