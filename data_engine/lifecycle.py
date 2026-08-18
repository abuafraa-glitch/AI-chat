"""Phase 6 data lifecycle coordinator.

This module is deliberately offline and deterministic.  It composes the existing
preparation helpers and adds run-level accounting, provenance, and a validation
gate without creating a second storage authority.
"""
from __future__ import annotations

import hashlib
import json
import logging
import re
import time
import uuid
from dataclasses import asdict, dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping, Optional, Sequence

from data_engine.preparation.data_validator import DataValidator
from data_engine.preparation.language_detector import LanguageDetector
from data_engine.preparation.quality_scorer import QualityScorer
from services.data_service.dataset_versioner import DatasetVersioner

logger = logging.getLogger(__name__)


class DatasetStatus(str, Enum):
    CREATED = "CREATED"
    PROCESSING = "PROCESSING"
    VALIDATING = "VALIDATING"
    VALID = "VALID"
    INVALID = "INVALID"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    FAILED = "FAILED"


@dataclass(frozen=True)
class SourceMetadata:
    source_id: str
    source_type: str
    source_uri: str = ""
    license: str = ""
    provenance: str = ""
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass
class StageReport:
    name: str
    input_count: int
    output_count: int
    rejected_count: int = 0
    reason_counts: dict[str, int] = field(default_factory=dict)
    started_at: float = field(default_factory=time.time)
    completed_at: float = 0.0

    @property
    def duration_ms(self) -> int:
        end = self.completed_at or time.time()
        return max(0, int((end - self.started_at) * 1000))

    def reject(self, reason: str, count: int = 1) -> None:
        self.rejected_count += count
        self.reason_counts[reason] = self.reason_counts.get(reason, 0) + count

    def finish(self, output_count: int) -> "StageReport":
        self.output_count = output_count
        self.completed_at = time.time()
        return self


@dataclass
class DatasetRun:
    run_id: str
    dataset_id: str
    dataset_version: str
    source: SourceMetadata
    status: DatasetStatus
    created_at: float
    records: list[dict[str, Any]] = field(default_factory=list, repr=False)
    stages: list[StageReport] = field(default_factory=list)
    record_count: int = 0
    quality_statistics: dict[str, Any] = field(default_factory=dict)
    validation_report: dict[str, Any] = field(default_factory=dict)
    processing_config: dict[str, Any] = field(default_factory=dict)
    checksum: str = ""
    artifact_path: str = ""
    error: str = ""

    def manifest(self) -> dict[str, Any]:
        data = asdict(self)
        data["status"] = self.status.value
        data["records"] = []
        data["source"] = asdict(self.source)
        return data


class DataEngine:
    """Canonical offline data lifecycle authority for Phase 6."""

    _PII_PATTERNS = {
        "email": re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I),
        "phone": re.compile(r"(?<!\d)(?:\+?\d[\d .()\-]{7,}\d)(?!\d)"),
        "credit_card": re.compile(r"(?<!\d)(?:\d[ -]?){13,19}(?!\d)"),
    }

    def __init__(
        self,
        *,
        storage_dir: str = "storage_data/phase6",
        dataset_versioner: Optional[DatasetVersioner] = None,
        supported_languages: Optional[set[str]] = None,
        safety_terms: Optional[set[str]] = None,
        pii_mode: str = "redact",
    ) -> None:
        if pii_mode not in {"redact", "reject"}:
            raise ValueError("pii_mode must be redact or reject")
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.versioner = dataset_versioner or DatasetVersioner(
            base_dir=str(self.storage_dir / "datasets")
        )
        self.validator = DataValidator()
        self.language_detector = LanguageDetector()
        self.quality_scorer = QualityScorer()
        self.supported_languages = supported_languages or {"ar", "en"}
        self.safety_terms = {term.casefold() for term in (safety_terms or set())}
        self.pii_mode = pii_mode

    def ingest(
        self,
        source: SourceMetadata,
        fetch: Callable[[], Sequence[Mapping[str, Any]]],
        *,
        dataset_id: Optional[str] = None,
        min_quality_score: int = 50,
        chunk_size: int = 512,
    ) -> DatasetRun:
        """Fetch a source and process it; source errors become FAILED, never success."""
        run = DatasetRun(
            run_id=f"data_{uuid.uuid4().hex}",
            dataset_id=dataset_id or source.source_id,
            dataset_version="pending",
            source=source,
            status=DatasetStatus.CREATED,
            created_at=time.time(),
            processing_config={
                "min_quality_score": min_quality_score,
                "chunk_size": chunk_size,
                "supported_languages": sorted(self.supported_languages),
                "pii_mode": self.pii_mode,
            },
        )
        try:
            run.status = DatasetStatus.PROCESSING
            raw = [dict(item) for item in fetch()]
            if not raw:
                run.status = DatasetStatus.INVALID
                run.error = "source returned no records"
                run.validation_report = {"reason": run.error}
                self._persist_manifest(run)
                return run
            run.records = self._process(run, raw, min_quality_score, chunk_size)
            run.record_count = len(run.records)
            run.checksum = self._checksum(run.records)
            run.status = DatasetStatus.VALIDATING
            run.validation_report = self._validate_gate(run)
            if not run.validation_report["valid"]:
                run.status = DatasetStatus.INVALID
                self._persist_manifest(run)
                return run
            version = self.versioner.create_version(
                run.records,
                name=run.dataset_id,
                version="v1",
                metadata={
                    "run_id": run.run_id,
                    "source": asdict(source),
                    "stages": [asdict(stage) for stage in run.stages],
                    "validation": run.validation_report,
                    "processing_config": run.processing_config,
                },
            )
            version.source_id = source.source_id
            version.status = DatasetStatus.APPROVED.value
            version.is_valid = True
            version.metadata.update({
                "source_id": source.source_id,
                "source_type": source.source_type,
                "source_uri": source.source_uri,
                "license": source.license,
                "provenance": source.provenance,
            })
            version.lineage = {
                "source": source.source_id,
                "raw_dataset": f"{run.run_id}:raw",
                "processed_dataset": f"{run.run_id}:processed",
                "dataset_version": version.version_id,
            }
            version.validation_report = run.validation_report
            version.processing_config = run.processing_config
            self.versioner._versions[version.version_id] = version
            self.versioner._save_registry()
            run.dataset_version = version.version
            run.artifact_path = version.path
            run.status = DatasetStatus.APPROVED
            self._persist_manifest(run)
            return run
        except Exception as exc:
            run.status = DatasetStatus.FAILED
            run.error = f"{type(exc).__name__}: {exc}"
            self._persist_manifest(run)
            logger.exception("Data lifecycle failed for %s", run.run_id)
            return run

    def _process(
        self,
        run: DatasetRun,
        raw: list[dict[str, Any]],
        min_quality_score: int,
        chunk_size: int,
    ) -> list[dict[str, Any]]:
        normalized = self._stage_normalize(run, raw)
        validated = self._stage_validate(run, normalized)
        language_ok = self._stage_language(run, validated)
        filtered = self._stage_safety_pii(run, language_ok)
        scored = self._stage_quality(run, filtered, min_quality_score)
        unique = self._stage_dedup(run, scored)
        return self._stage_chunk(run, unique, chunk_size)

    def _stage_normalize(self, run: DatasetRun, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        stage = self._start(run, "normalize", len(records))
        output: list[dict[str, Any]] = []
        for record in records:
            item = dict(record)
            item["instruction"] = str(item.get("instruction", item.get("input", ""))).strip()
            item["output"] = str(item.get("output", item.get("response", ""))).strip()
            if not item.get("instruction") or not item.get("output"):
                stage.reject("empty_record")
                continue
            item.setdefault("source_id", run.source.source_id)
            item.setdefault("source_type", run.source.source_type)
            item["record_id"] = str(item.get("record_id") or uuid.uuid5(uuid.NAMESPACE_URL, self._record_key(item)))
            output.append(item)
        run.stages.append(stage.finish(len(output)))
        return output

    def _stage_validate(self, run: DatasetRun, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        stage = self._start(run, "validate", len(records))
        output = []
        for record in self.validator.validate_dataset(records):
            if record.get("is_valid"):
                output.append(record)
            else:
                for reason in record.get("validation_errors", ["invalid_record"]):
                    stage.reject(reason)
        run.stages.append(stage.finish(len(output)))
        return output

    def _stage_language(self, run: DatasetRun, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        stage = self._start(run, "language", len(records))
        output = []
        for record in records:
            instruction_lang = self.language_detector.detect_language(record["instruction"])
            output_lang = self.language_detector.detect_language(record["output"])
            record["instruction_lang"] = instruction_lang
            record["output_lang"] = output_lang
            if instruction_lang == "unknown" or output_lang == "unknown":
                stage.reject("unknown_language")
            elif instruction_lang not in self.supported_languages or output_lang not in self.supported_languages:
                stage.reject("unsupported_language")
            else:
                output.append(record)
        run.stages.append(stage.finish(len(output)))
        return output

    def _stage_safety_pii(self, run: DatasetRun, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        stage = self._start(run, "pii_safety", len(records))
        output = []
        for record in records:
            text = f"{record['instruction']}\n{record['output']}"
            safety_hit = next((term for term in self.safety_terms if term in text.casefold()), None)
            if safety_hit:
                stage.reject("unsafe_content")
                continue
            pii_types = [name for name, pattern in self._PII_PATTERNS.items() if pattern.search(text)]
            if pii_types and self.pii_mode == "reject":
                stage.reject("pii_detected")
                continue
            if pii_types:
                for field_name in ("instruction", "output"):
                    value = record[field_name]
                    for name, pattern in self._PII_PATTERNS.items():
                        value = pattern.sub(f"[REDACTED_{name.upper()}]", value)
                    record[field_name] = value
                record["pii_status"] = "redacted"
                record["pii_types"] = pii_types
            else:
                record["pii_status"] = "accepted"
            output.append(record)
        run.stages.append(stage.finish(len(output)))
        return output

    def _stage_quality(self, run: DatasetRun, records: list[dict[str, Any]], threshold: int) -> list[dict[str, Any]]:
        stage = self._start(run, "quality", len(records))
        output = []
        scored = self.quality_scorer.score_dataset(records)
        scores = []
        for record in scored:
            score = int(record.get("quality_score", 0))
            scores.append(score)
            if score < threshold:
                stage.reject("quality_below_threshold")
            else:
                output.append(record)
        run.quality_statistics = {
            "min": min(scores) if scores else 0,
            "max": max(scores) if scores else 0,
            "mean": round(sum(scores) / len(scores), 3) if scores else 0,
            "threshold": threshold,
        }
        run.stages.append(stage.finish(len(output)))
        return output

    def _stage_dedup(self, run: DatasetRun, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        stage = self._start(run, "deduplication", len(records))
        seen: set[str] = set()
        output = []
        for record in records:
            key = self._record_key(record)
            if key in seen:
                stage.reject("exact_duplicate")
            else:
                seen.add(key)
                output.append(record)
        run.stages.append(stage.finish(len(output)))
        return output

    def _stage_chunk(self, run: DatasetRun, records: list[dict[str, Any]], chunk_size: int) -> list[dict[str, Any]]:
        stage = self._start(run, "chunking", len(records))
        if chunk_size < 1:
            raise ValueError("chunk_size must be positive")
        output = []
        for record in records:
            text = f"{record['instruction']}\n{record['output']}"
            for sequence, start in enumerate(range(0, len(text), chunk_size)):
                chunk = dict(record)
                content = text[start:start + chunk_size]
                chunk["document_id"] = record["record_id"]
                chunk["chunk_id"] = hashlib.sha256(f"{record['record_id']}:{sequence}:{content}".encode()).hexdigest()[:24]
                chunk["chunk_sequence"] = sequence
                chunk["chunk_start"] = start
                chunk["chunk_end"] = start + len(content)
                chunk["chunk_text"] = content
                output.append(chunk)
        run.stages.append(stage.finish(len(output)))
        return output

    def _validate_gate(self, run: DatasetRun) -> dict[str, Any]:
        reasons: list[str] = []
        if not run.records:
            reasons.append("empty_dataset")
        if any(not r.get("record_id") or not r.get("chunk_id") for r in run.records):
            reasons.append("missing_metadata")
        if any(r.get("pii_status") not in {"accepted", "redacted"} for r in run.records):
            reasons.append("safety_or_pii_policy")
        return {"valid": not reasons, "reasons": reasons, "record_count": len(run.records)}

    @staticmethod
    def _record_key(record: Mapping[str, Any]) -> str:
        content = f"{record.get('instruction', '')}\n{record.get('output', '')}"
        return hashlib.sha256(content.encode("utf-8")).hexdigest()

    @staticmethod
    def _checksum(records: Sequence[Mapping[str, Any]]) -> str:
        payload = json.dumps(list(records), ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    @staticmethod
    def _start(run: DatasetRun, name: str, input_count: int) -> StageReport:
        return StageReport(name=name, input_count=input_count, output_count=0)

    def _persist_manifest(self, run: DatasetRun) -> None:
        path = self.storage_dir / f"{run.run_id}.json"
        path.write_text(json.dumps(run.manifest(), ensure_ascii=False, indent=2), encoding="utf-8")


__all__ = ["DataEngine", "DatasetRun", "DatasetStatus", "SourceMetadata", "StageReport"]
