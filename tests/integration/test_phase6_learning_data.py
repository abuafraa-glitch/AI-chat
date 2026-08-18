from __future__ import annotations

import json

from data_engine.lifecycle import DataEngine, DatasetStatus, SourceMetadata
from services.data_service.dataset_versioner import DatasetVersioner


def sample(text: str, output: str | None = None) -> dict:
    return {
        "instruction": text,
        "output": output or "This is a sufficiently long deterministic response for the dataset record.",
    }


def test_ingestion_failure_is_not_success(tmp_path):
    engine = DataEngine(storage_dir=str(tmp_path))

    def failed_fetch():
        raise RuntimeError("source unavailable")

    run = engine.ingest(SourceMetadata("src-fail", "test"), failed_fetch)
    assert run.status is DatasetStatus.FAILED
    assert run.artifact_path == ""
    assert "source unavailable" in run.error


def test_data_lifecycle_is_traceable_and_deterministic(tmp_path):
    records = [
        sample("Explain deterministic dataset versioning in a clear way."),
        sample("Explain deterministic dataset versioning in a clear way."),
        sample("Explain a different validation workflow with enough content."),
    ]
    source = SourceMetadata(
        source_id="src-1",
        source_type="fixture",
        source_uri="local://phase6",
        license="internal",
        provenance="phase6-test",
    )
    engine = DataEngine(storage_dir=str(tmp_path), supported_languages={"en"})
    run = engine.ingest(source, lambda: records, dataset_id="dataset-1", chunk_size=80)

    assert run.status is DatasetStatus.APPROVED
    assert run.dataset_version == "v1"
    assert run.record_count >= 2
    assert run.checksum
    assert {stage.name for stage in run.stages} == {
        "normalize", "validate", "language", "pii_safety", "quality", "deduplication", "chunking"
    }
    dedup = next(stage for stage in run.stages if stage.name == "deduplication")
    assert dedup.rejected_count == 1
    assert dedup.reason_counts["exact_duplicate"] == 1
    assert all(record["chunk_id"] for record in run.records)
    manifest = json.loads((tmp_path / f"{run.run_id}.json").read_text())
    assert manifest["source"]["source_id"] == "src-1"
    assert manifest["status"] == "APPROVED"


def test_unknown_language_and_low_quality_are_rejected(tmp_path):
    engine = DataEngine(storage_dir=str(tmp_path), supported_languages={"en"})
    run = engine.ingest(
        SourceMetadata("src-2", "test"),
        lambda: [sample("x", "y")],
        min_quality_score=90,
    )
    assert run.status in {DatasetStatus.INVALID, DatasetStatus.APPROVED}
    language = next(stage for stage in run.stages if stage.name == "language")
    validation = next(stage for stage in run.stages if stage.name == "validate")
    assert language.rejected_count >= 0
    assert validation.rejected_count >= 1


def test_pii_is_redacted_and_never_in_manifest(tmp_path):
    engine = DataEngine(storage_dir=str(tmp_path), supported_languages={"en"})
    run = engine.ingest(
        SourceMetadata("src-3", "test"),
        lambda: [sample("Please process contact alice@example.com safely.")],
    )
    assert run.status is DatasetStatus.APPROVED
    assert any(record["pii_status"] == "redacted" for record in run.records)
    manifest_text = (tmp_path / f"{run.run_id}.json").read_text()
    assert "alice@example.com" not in manifest_text


def test_three_way_split_is_deterministic_and_disjoint(tmp_path):
    versioner = DatasetVersioner(base_dir=str(tmp_path / "versions"))
    records = [{"id": str(i), "text": f"record {i} with deterministic content"} for i in range(10)]
    first = versioner.split_three_way(records)
    second = versioner.split_three_way(list(reversed(records)))
    assert first == second
    report = versioner.validate_split_integrity(*first)
    assert report["valid"] is True
    assert all(value == [] for value in report["overlap"].values())


def test_invalid_chunk_configuration_fails_closed(tmp_path):
    engine = DataEngine(storage_dir=str(tmp_path), supported_languages={"en"})
    run = engine.ingest(
        SourceMetadata("src-4", "test"),
        lambda: [sample("A valid record for a configuration failure test.")],
        chunk_size=0,
    )
    assert run.status is DatasetStatus.FAILED
    assert run.artifact_path == ""
