"""Canonical Phase 6 learning lifecycle coordinator."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Mapping, Optional, Sequence

from core.model.model_registry import ModelArtifactRecord, ModelArtifactStatus, ModelRegistry
from data_engine.lifecycle import DataEngine, DatasetRun, DatasetStatus, SourceMetadata
from .phase6_lifecycle import (
    EvaluationPipelineLifecycle,
    EvaluationRun,
    EvaluationStatus,
    TrainingPipelineLifecycle,
    TrainingRun,
    TrainingStatus,
)


@dataclass
class LearningLifecycleResult:
    dataset: DatasetRun
    training: Optional[TrainingRun] = None
    evaluation: Optional[EvaluationRun] = None
    artifact: Optional[ModelArtifactRecord] = None


class LearningLifecycleCoordinator:
    """Single authority for dataset -> training -> evaluation -> promotion."""

    def __init__(
        self,
        *,
        data_engine: Optional[DataEngine] = None,
        training: Optional[TrainingPipelineLifecycle] = None,
        evaluation: Optional[EvaluationPipelineLifecycle] = None,
        registry: Optional[ModelRegistry] = None,
    ) -> None:
        self.data_engine = data_engine or DataEngine()
        self.training = training or TrainingPipelineLifecycle()
        self.evaluation = evaluation or EvaluationPipelineLifecycle()
        self.registry = registry or ModelRegistry()

    def prepare_dataset(
        self,
        source: SourceMetadata,
        fetch: Callable[[], Sequence[Mapping[str, Any]]],
        **config: Any,
    ) -> DatasetRun:
        return self.data_engine.ingest(source, fetch, **config)

    def queue_training(
        self,
        dataset: DatasetRun,
        *,
        base_model: str,
        base_model_version: str,
        training_config: Optional[dict[str, Any]] = None,
        code_version: str = "",
    ) -> TrainingRun:
        if dataset.status is not DatasetStatus.APPROVED:
            raise ValueError("training requires an APPROVED dataset")
        return self.training.create_run(
            dataset_id=dataset.dataset_id,
            dataset_version=dataset.dataset_version,
            dataset_path=dataset.artifact_path,
            base_model=base_model,
            base_model_version=base_model_version,
            training_config=training_config,
            code_version=code_version,
            dataset_checksum=dataset.checksum,
            dataset_lineage={"source": dataset.source.provenance, "source_id": dataset.source.source_id, "dataset_run_id": dataset.run_id},
        )

    def complete_training(
        self,
        training: TrainingRun,
        *,
        artifact_location: str,
        metrics: Mapping[str, Any],
    ) -> TrainingRun:
        if training.status is TrainingStatus.QUEUED:
            self.training.start(training)
        return self.training.complete(training, artifact_location, metrics)

    def evaluate_training(
        self,
        training: TrainingRun,
        *,
        model_id: str,
        model_version: str,
        benchmark_id: str,
        benchmark_version: str,
        sample_count: int = 0,
        benchmark_path: str = "",
        benchmark_source: str = "",
        benchmark_split: str = "test",
        infer_and_measure: Optional[Callable[[], Mapping[str, Any]]] = None,
        thresholds: Optional[Mapping[str, float]] = None,
    ) -> EvaluationRun:
        if training.status is not TrainingStatus.COMPLETED:
            raise ValueError("evaluation requires a COMPLETED training run")
        evaluation = self.evaluation.create_run(
            model_id=model_id,
            model_version=model_version,
            artifact_location=training.artifact_location,
            benchmark_id=benchmark_id,
            benchmark_version=benchmark_version,
            sample_count=sample_count,
            benchmark_path=benchmark_path,
            benchmark_source=benchmark_source,
            benchmark_split=benchmark_split,
        )
        if evaluation.status is EvaluationStatus.BLOCKED:
            return evaluation
        if infer_and_measure is None:
            evaluation.status = EvaluationStatus.BLOCKED
            evaluation.error = "real_evaluator_required"
            self.evaluation._persist(evaluation)
            return evaluation
        return self.evaluation.run(evaluation, infer_and_measure, thresholds=thresholds)

    def register_and_approve(
        self,
        training: TrainingRun,
        evaluation: EvaluationRun,
        *,
        model_id: str,
        model_version: str,
        model_type: str,
    ) -> ModelArtifactRecord:
        if training.status is not TrainingStatus.COMPLETED:
            raise ValueError("registration requires completed training")
        if evaluation.status is not EvaluationStatus.COMPLETED or not evaluation.passes_threshold:
            raise ValueError("registration requires a passing completed evaluation")
        record = ModelArtifactRecord(
            model_id=model_id,
            model_version=model_version,
            model_type=model_type,
            artifact_location=training.artifact_location,
            base_model=training.base_model,
            dataset_version=training.dataset_version,
            training_run_id=training.training_run_id,
            evaluation_id=evaluation.evaluation_id,
            metrics=evaluation.metrics,
            dataset_checksum=training.dataset_checksum,
            benchmark_checksum=evaluation.benchmark_checksum,
            lineage={"dataset": training.dataset_lineage, "evaluation": evaluation.metric_provenance},
            status=ModelArtifactStatus.TRAINED,
        )
        self.registry.register_artifact(record)
        self.registry.mark_evaluated(
            model_id,
            model_version,
            evaluation.evaluation_id,
            evaluation.metrics,
            evaluation.passes_threshold,
        )
        return self.registry.approve(model_id, model_version)


__all__ = ["LearningLifecycleCoordinator", "LearningLifecycleResult"]
