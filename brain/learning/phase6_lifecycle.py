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


@dataclass
class TrainingRun:
    training_run_id: str
    dataset_id: str
    dataset_version: str
    base_model: str
    base_model_version: str
    training_config: dict[str, Any]
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
        root = Path(location)
        reasons: list[str] = []
        if not root.is_dir():
            return ArtifactValidation(False, ("artifact_directory_missing",))
        config_path = root / "config.json"
        if not config_path.is_file():
            reasons.append("config_missing")
            config: dict[str, Any] = {}
        else:
            try:
                config = json.loads(config_path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                config = {}
                reasons.append("config_invalid")
        if not any((root / name).is_file() for name in self.WEIGHT_NAMES):
            reasons.append("weights_missing")
        if not any((root / name).is_file() for name in self.TOKENIZER_NAMES):
            reasons.append("tokenizer_missing")
        architectures = config.get("architectures", [])
        if architectures and not any("CausalLM" in str(item) for item in architectures):
            reasons.append("incompatible_model_architecture")
        if not config.get("model_type"):
            reasons.append("model_type_missing")
        checksum = self._directory_checksum(root) if not reasons else ""
        return ArtifactValidation(
            valid=not reasons,
            reasons=tuple(reasons),
            checksum=checksum,
            metadata={"model_type": config.get("model_type", ""), "architectures": architectures},
        )

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
    ) -> TrainingRun:
        run = TrainingRun(
            training_run_id=f"train_{uuid.uuid4().hex}",
            dataset_id=dataset_id,
            dataset_version=dataset_version,
            base_model=base_model,
            base_model_version=base_model_version,
            training_config=dict(training_config or {}),
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

    def create_run(
        self,
        *,
        model_id: str,
        model_version: str,
        artifact_location: str,
        benchmark_id: str,
        benchmark_version: str,
        sample_count: int,
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
            evaluation.passes_threshold = all(
                float(metrics[name]) >= float(limit)
                for name, limit in (thresholds or {}).items()
                if name in metrics
            )
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
    "ArtifactValidation", "ArtifactValidator", "EvaluationPipelineLifecycle", "EvaluationRun",
    "EvaluationStatus", "TrainingPipelineLifecycle", "TrainingRun", "TrainingStatus",
]
