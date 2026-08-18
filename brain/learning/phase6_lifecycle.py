"""Phase 6 training/evaluation lifecycle contracts.

The module owns lifecycle state and gates; model training and inference remain in
existing lower-level pipelines. It never manufactures metrics or artifacts.
"""
from __future__ import annotations

import hashlib
import json
import os
import platform
import subprocess
import time
import uuid
from dataclasses import asdict, dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Mapping, Optional

from core.model.artifact_validation import validate_artifact_directory


class TrainingStatus(str, Enum):
    QUEUED = "QUEUED"
    RUNNING = "RUNNING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    BLOCKED = "BLOCKED"


class EvaluationStatus(str, Enum):
    QUEUED = "QUEUED"
    RUNNING = "RUNNING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    BLOCKED = "BLOCKED"


@dataclass(frozen=True)
class BenchmarkDataset:
    benchmark_id: str
    benchmark_version: str
    path: str
    sample_count: int
    checksum: str
    source: str = ""
    split: str = "test"
    metadata: Mapping[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class TrainingRun:
    training_run_id: str
    dataset_id: str
    dataset_version: str
    base_model: str
    base_model_version: str
    training_config: dict[str, Any]
    dataset_checksum: str = ""
    dataset_lineage: dict[str, Any] = field(default_factory=dict)
    started_at: float = 0.0
    completed_at: float = 0.0
    status: TrainingStatus = TrainingStatus.QUEUED
    metrics: dict[str, Any] = field(default_factory=dict)
    artifact_location: str = ""
    code_version: str = ""
    error: str = ""
    environment: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        value = asdict(self)
        value["status"] = self.status.value
        return value


@dataclass
class EvaluationRun:
    evaluation_id: str
    model_id: str
    model_version: str
    artifact_location: str
    benchmark_id: str
    benchmark_version: str
    sample_count: int
    status: EvaluationStatus = EvaluationStatus.QUEUED
    started_at: float = 0.0
    completed_at: float = 0.0
    metrics: dict[str, Any] = field(default_factory=dict)
    metric_provenance: dict[str, Any] = field(default_factory=dict)
    benchmark_checksum: str = ""
    passes_threshold: bool = False
    error: str = ""

    def to_dict(self) -> dict[str, Any]:
        value = asdict(self)
        value["status"] = self.status.value
        return value


@dataclass(frozen=True)
class ArtifactValidation:
    valid: bool
    reasons: tuple[str, ...] = ()
    checksum: str = ""
    metadata: Mapping[str, Any] = field(default_factory=dict)


class ArtifactValidator:
    """Validates a real local causal-LM artifact without downloading anything."""

    WEIGHT_NAMES = ("model.safetensors", "pytorch_model.bin", "pytorch_model.bin.index.json")
    TOKENIZER_NAMES = ("tokenizer.json", "tokenizer.model", "tokenizer_config.json")

    def validate(self, location: str) -> ArtifactValidation:
        valid, reasons, checksum, metadata = validate_artifact_directory(location)
        return ArtifactValidation(valid=valid, reasons=reasons, checksum=checksum, metadata=metadata)

    @staticmethod
    def _directory_checksum(root: Path) -> str:
        digest = hashlib.sha256()
        for path in sorted(p for p in root.rglob("*") if p.is_file()):
            digest.update(str(path.relative_to(root)).encode())
            digest.update(path.read_bytes())
        return digest.hexdigest()


class TrainingPipelineLifecycle:
    """Lifecycle gate around the existing real training pipeline."""

    def __init__(self, storage_dir: str = "storage_data/phase6/training") -> None:
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.artifact_validator = ArtifactValidator()

    def create_run(
        self,
        *,
        dataset_id: str,
        dataset_version: str,
        dataset_path: str,
        base_model: str,
        base_model_version: str,
        training_config: Optional[dict[str, Any]] = None,
        code_version: str = "",
        dataset_checksum: str = "",
        dataset_lineage: Optional[Mapping[str, Any]] = None,
    ) -> TrainingRun:
        run = TrainingRun(
            training_run_id=f"train_{uuid.uuid4().hex}",
            dataset_id=dataset_id,
            dataset_version=dataset_version,
            base_model=base_model,
            base_model_version=base_model_version,
            training_config=dict(training_config or {}),
            dataset_checksum=dataset_checksum,
            dataset_lineage=dict(dataset_lineage or {}),
            code_version=code_version,
            environment={"python": platform.python_version(), "platform": platform.platform()},
        )
        if not Path(dataset_path).is_file():
            run.status = TrainingStatus.BLOCKED
            run.error = "dataset_missing"
        elif not self._has_records(dataset_path):
            run.status = TrainingStatus.BLOCKED
            run.error = "dataset_empty_or_corrupt"
        elif not base_model:
            run.status = TrainingStatus.BLOCKED
            run.error = "base_model_missing"
        else:
            run.status = TrainingStatus.QUEUED
        self._persist(run)
        return run

    def start(self, run: TrainingRun) -> TrainingRun:
        if run.status is not TrainingStatus.QUEUED:
            return run
        run.status = TrainingStatus.RUNNING
        run.started_at = time.time()
        self._persist(run)
        return run

    def complete(self, run: TrainingRun, artifact_location: str, metrics: Mapping[str, Any]) -> TrainingRun:
        validation = self.artifact_validator.validate(artifact_location)
        if not validation.valid:
            run.status = TrainingStatus.FAILED
            run.error = "artifact_invalid:" + ",".join(validation.reasons)
            run.completed_at = time.time()
            self._persist(run)
            return run
        run.artifact_location = artifact_location
        run.metrics = dict(metrics)
        run.metrics["artifact_checksum"] = validation.checksum
        run.status = TrainingStatus.COMPLETED
        run.completed_at = time.time()
        self._persist(run)
        return run

    def fail(self, run: TrainingRun, error: str) -> TrainingRun:
        run.status = TrainingStatus.FAILED
        run.error = error
        run.completed_at = time.time()
        self._persist(run)
        return run

    @staticmethod
    def _has_records(dataset_path: str) -> bool:
        path = Path(dataset_path)
        try:
            if path.suffix == ".jsonl":
                return any(line.strip() for line in path.read_text(encoding="utf-8").splitlines())
            data = json.loads(path.read_text(encoding="utf-8"))
            return isinstance(data, list) and bool(data)
        except (OSError, UnicodeError, json.JSONDecodeError):
            return False

    def _persist(self, run: TrainingRun) -> None:
        (self.storage_dir / f"{run.training_run_id}.json").write_text(
            json.dumps(run.to_dict(), ensure_ascii=False, indent=2), encoding="utf-8"
        )


class EvaluationPipelineLifecycle:
    """Evaluation gate that only reports metrics from a real callable/inference."""

    def __init__(self, storage_dir: str = "storage_data/phase6/evaluation") -> None:
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.artifact_validator = ArtifactValidator()

    @staticmethod
    def _benchmark_checksum(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def validate_benchmark_dataset(
        self,
        *,
        benchmark_id: str,
        benchmark_version: str,
        benchmark_path: str,
        source: str = "",
        split: str = "test",
    ) -> tuple[Optional[BenchmarkDataset], str]:
        path = Path(benchmark_path)
        if not path.is_file():
            return None, "benchmark_missing"
        try:
            if path.suffix.lower() == ".jsonl":
                records = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
            else:
                records = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(records, list) or not records or not all(isinstance(item, dict) for item in records):
                return None, "benchmark_invalid"
        except (OSError, UnicodeError, json.JSONDecodeError):
            return None, "benchmark_invalid"
        dataset = BenchmarkDataset(
            benchmark_id=benchmark_id,
            benchmark_version=benchmark_version,
            path=str(path),
            sample_count=len(records),
            checksum=self._benchmark_checksum(path),
            source=source,
            split=split,
            metadata={"record_schema": "object"},
        )
        return dataset, ""

    def create_run(
        self,
        *,
        model_id: str,
        model_version: str,
        artifact_location: str,
        benchmark_id: str,
        benchmark_version: str,
        sample_count: int = 0,
        benchmark_path: str = "",
        benchmark_source: str = "",
        benchmark_split: str = "test",
    ) -> EvaluationRun:
        run = EvaluationRun(
            evaluation_id=f"eval_{uuid.uuid4().hex}",
            model_id=model_id,
            model_version=model_version,
            artifact_location=artifact_location,
            benchmark_id=benchmark_id,
            benchmark_version=benchmark_version,
            sample_count=sample_count,
        )
        validation = self.artifact_validator.validate(artifact_location)
        if not validation.valid:
            run.status = EvaluationStatus.BLOCKED
            run.error = "artifact_invalid:" + ",".join(validation.reasons)
        elif benchmark_path:
            benchmark, benchmark_error = self.validate_benchmark_dataset(
                benchmark_id=benchmark_id,
                benchmark_version=benchmark_version,
                benchmark_path=benchmark_path,
                source=benchmark_source,
                split=benchmark_split,
            )
            if benchmark is None:
                run.status = EvaluationStatus.BLOCKED
                run.error = benchmark_error
            else:
                run.sample_count = benchmark.sample_count
                run.benchmark_checksum = benchmark.checksum
                run.metric_provenance["benchmark"] = benchmark.to_dict()
        elif sample_count <= 0:
            run.status = EvaluationStatus.BLOCKED
            run.error = "benchmark_empty"
        self._persist(run)
        return run

    def run(
        self,
        evaluation: EvaluationRun,
        infer_and_measure: Callable[[], Mapping[str, Any]],
        *,
        thresholds: Optional[Mapping[str, float]] = None,
    ) -> EvaluationRun:
        if evaluation.status is not EvaluationStatus.QUEUED:
            return evaluation
        evaluation.status = EvaluationStatus.RUNNING
        evaluation.started_at = time.time()
        try:
            metrics = dict(infer_and_measure())
            if not metrics:
                raise ValueError("empty_metrics")
            evaluation.metrics = metrics
            evaluation.metric_provenance.setdefault("evaluation", {})
            evaluation.metric_provenance["evaluation"].update({
                "benchmark_id": evaluation.benchmark_id,
                "benchmark_version": evaluation.benchmark_version,
                "sample_count": evaluation.sample_count,
                "measured_at": time.time(),
            })
            required_thresholds = dict(thresholds or {})
            missing_metrics = sorted(set(required_thresholds) - set(metrics))
            evaluation.passes_threshold = not missing_metrics and all(
                float(metrics[name]) >= float(limit)
                for name, limit in required_thresholds.items()
            )
            if missing_metrics:
                evaluation.error = "missing_metrics:" + ",".join(missing_metrics)
            evaluation.status = EvaluationStatus.COMPLETED
        except Exception as exc:
            evaluation.status = EvaluationStatus.FAILED
            evaluation.error = f"{type(exc).__name__}: {exc}"
        evaluation.completed_at = time.time()
        self._persist(evaluation)
        return evaluation

    def _persist(self, evaluation: EvaluationRun) -> None:
        (self.storage_dir / f"{evaluation.evaluation_id}.json").write_text(
            json.dumps(evaluation.to_dict(), ensure_ascii=False, indent=2), encoding="utf-8"
        )


__all__ = [
    "ArtifactValidation", "ArtifactValidator", "BenchmarkDataset", "EvaluationPipelineLifecycle", "EvaluationRun",
    "EvaluationStatus", "TrainingPipelineLifecycle", "TrainingRun", "TrainingStatus",
]
