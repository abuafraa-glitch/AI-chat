from __future__ import annotations

import logging
import time
from dataclasses import asdict, dataclass, field
from enum import Enum
from pathlib import Path
from threading import Lock
from typing import Any, Dict, List, Mapping, Optional

from .artifact_validation import validate_artifact_directory
from .model_config import ModelConfig

logger = logging.getLogger(__name__)


class ModelArtifactStatus(str, Enum):
    CREATED = "CREATED"
    TRAINED = "TRAINED"
    EVALUATED = "EVALUATED"
    APPROVED = "APPROVED"
    STAGING = "STAGING"
    PRODUCTION = "PRODUCTION"
    REJECTED = "REJECTED"
    DEPRECATED = "DEPRECATED"


@dataclass
class ModelArtifactRecord:
    model_id: str
    model_version: str
    model_type: str
    artifact_location: str
    base_model: str
    dataset_version: str
    training_run_id: str
    evaluation_id: str = ""
    metrics: Dict[str, Any] = field(default_factory=dict)
    status: ModelArtifactStatus = ModelArtifactStatus.CREATED
    created_at: float = field(default_factory=time.time)
    error: str = ""
    artifact_checksum: str = ""
    artifact_metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        value = asdict(self)
        value["status"] = self.status.value
        return value


class ModelRegistry:
    """Thread-safe in-process registry for ModelConfig objects."""

    _instance: Optional["ModelRegistry"] = None
    _lock: Lock = Lock()

    def __new__(cls) -> "ModelRegistry":
        with cls._lock:
            if cls._instance is None:
                cls._instance = super().__new__(cls)
                cls._instance._initialized = False
        return cls._instance

    def __init__(self) -> None:
        if self._initialized:
            return
        self._configs: Dict[str, ModelConfig] = {}
        self._artifacts: Dict[str, ModelArtifactRecord] = {}
        self._initialized = True
        self._seed_defaults()
        logger.info("ModelRegistry initialized with %d defaults", len(self._configs))

    def _seed_defaults(self) -> None:
        defaults = [
            ModelConfig(
                model_id="llama3-8b",
                display_name="LLaMA 3 8B",
                tokenizer_type="llama",
                context_length=8192,
            ),
            ModelConfig(
                model_id="mistral-7b",
                display_name="Mistral 7B",
                tokenizer_type="mistral",
                context_length=8192,
            ),
            ModelConfig(
                model_id="ollama:llama3",
                display_name="Ollama LLaMA 3",
                backend="ollama",
                tokenizer_type="generic",
            ),
        ]
        for cfg in defaults:
            self._configs[cfg.model_id] = cfg

    def register(self, config: ModelConfig) -> None:
        self._configs[config.model_id] = config
        logger.info("Model registered: %s", config.model_id)

    def get(self, model_id: str) -> Optional[ModelConfig]:
        return self._configs.get(model_id)

    def get_or_raise(self, model_id: str) -> ModelConfig:
        cfg = self.get(model_id)
        if cfg is None:
            raise KeyError(f"Model '{model_id}' not found in registry")
        return cfg

    def list_models(self) -> List[Dict]:
        return [
            {
                "model_id": c.model_id,
                "display_name": c.display_name or c.model_id,
                "backend": c.backend,
                "context_length": c.context_length,
            }
            for c in self._configs.values()
        ]

    def register_artifact(self, record: ModelArtifactRecord) -> ModelArtifactRecord:
        """Register a trained artifact; evaluation/approval remain explicit gates."""
        if not record.model_id or not record.model_version:
            raise ValueError("model_id and model_version are required")
        valid, reasons, checksum, metadata = validate_artifact_directory(record.artifact_location)
        if not valid:
            raise ValueError("artifact_invalid:" + ",".join(reasons))
        record.artifact_checksum = checksum
        record.artifact_metadata = dict(metadata)
        if record.status not in {ModelArtifactStatus.CREATED, ModelArtifactStatus.TRAINED}:
            raise ValueError("new artifacts must start as CREATED or TRAINED")
        key = f"{record.model_id}:{record.model_version}"
        if key in self._artifacts:
            raise ValueError(f"artifact version already registered: {key}")
        self._artifacts[key] = record
        logger.info("Model artifact registered: %s", key)
        return record

    def get_artifact(self, model_id: str, model_version: str) -> Optional[ModelArtifactRecord]:
        return self._artifacts.get(f"{model_id}:{model_version}")

    def mark_evaluated(
        self,
        model_id: str,
        model_version: str,
        evaluation_id: str,
        metrics: Mapping[str, Any],
        passes_threshold: bool,
    ) -> ModelArtifactRecord:
        record = self._require_artifact(model_id, model_version)
        if not evaluation_id or not metrics:
            raise ValueError("evaluation evidence is required")
        record.evaluation_id = evaluation_id
        record.metrics = dict(metrics)
        record.status = ModelArtifactStatus.EVALUATED if passes_threshold else ModelArtifactStatus.REJECTED
        if not passes_threshold:
            record.error = "evaluation_threshold_failed"
        return record

    def approve(self, model_id: str, model_version: str) -> ModelArtifactRecord:
        record = self._require_artifact(model_id, model_version)
        if record.status is not ModelArtifactStatus.EVALUATED:
            raise ValueError("only an evaluated-passing artifact can be approved")
        record.status = ModelArtifactStatus.APPROVED
        return record

    def promote(self, model_id: str, model_version: str, target: ModelArtifactStatus) -> ModelArtifactRecord:
        record = self._require_artifact(model_id, model_version)
        if target not in {ModelArtifactStatus.STAGING, ModelArtifactStatus.PRODUCTION}:
            raise ValueError("target must be STAGING or PRODUCTION")
        if record.status is not ModelArtifactStatus.APPROVED:
            raise ValueError("promotion requires APPROVED status")
        record.status = target
        return record

    def reject(self, model_id: str, model_version: str, reason: str) -> ModelArtifactRecord:
        record = self._require_artifact(model_id, model_version)
        record.status = ModelArtifactStatus.REJECTED
        record.error = reason
        return record

    def list_artifacts(self) -> List[Dict[str, Any]]:
        return [record.to_dict() for record in self._artifacts.values()]

    def eligible_artifacts(self) -> List[ModelArtifactRecord]:
        return [
            record for record in self._artifacts.values()
            if record.status in {ModelArtifactStatus.STAGING, ModelArtifactStatus.PRODUCTION}
        ]

    def compare_versions(self, model_id: str, first: str, second: str) -> Dict[str, Any]:
        left = self._require_artifact(model_id, first)
        right = self._require_artifact(model_id, second)
        metric_names = sorted(set(left.metrics) | set(right.metrics))
        return {
            "model_id": model_id,
            "first": left.to_dict(),
            "second": right.to_dict(),
            "metric_delta": {
                name: (right.metrics.get(name), left.metrics.get(name))
                for name in metric_names
            },
        }

    def _require_artifact(self, model_id: str, model_version: str) -> ModelArtifactRecord:
        record = self.get_artifact(model_id, model_version)
        if record is None:
            raise KeyError(f"artifact '{model_id}:{model_version}' not found")
        return record

    def unregister(self, model_id: str) -> bool:
        if model_id in self._configs:
            del self._configs[model_id]
            logger.info("Model unregistered: %s", model_id)
            return True
        return False

    def __len__(self) -> int:
        return len(self._configs)
