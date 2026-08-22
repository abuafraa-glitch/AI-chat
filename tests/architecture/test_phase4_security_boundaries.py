"""Phase 4 boundary checks.

These tests are deliberately conservative: they prove source-level contracts only
and do not claim deployed E2E, GPU runtime, or cross-tenant isolation.
"""
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def test_canonical_security_and_routing_modules_exist():
    for rel in (
        "api/v1/ai/router.py",
        "services/chat/chat_service.py",
        "brain/brain_v3.py",
        "brain/model_router.py",
        "core/model/model_registry.py",
    ):
        assert (ROOT / rel).is_file(), rel


def test_hajeen_router_has_fail_closed_contract():
    source = _read("brain/model_router.py")
    assert "VERIFIED_BASE" in source
    assert "verification" in source.lower() or "verified_base" in source.lower()
    assert "raise" in source


def test_chat_service_uses_boundary_abstractions():
    source = _read("services/chat/chat_service.py")
    assert "inference_engine" in source
    assert "_brain" in source
    assert "native stream" in source


def test_gpu_direct_generate_is_classified_as_worker_runtime_call():
    source = _read("workers/distributed/gpu_worker.py")
    assert "model.generate(" in source
    assert "ModelLoader" in source
    assert "reserve_device" in source


def test_context_vocabulary_is_present_for_audit():
    corpus = "\n".join(
        _read(rel)
        for rel in (
            "services/chat/chat_service.py",
            "workers/tasks/inference_tasks.py",
            "workers/distributed/gpu_worker.py",
        )
        if (ROOT / rel).exists()
    )
    assert "request_id" in corpus or "stream_id" in corpus
    assert "model" in corpus.lower()


def test_phase4_does_not_include_model_weights():
    forbidden = {".safetensors", ".bin", ".pt", ".pth", ".gguf"}
    for path in (ROOT / "tests/architecture").rglob("*"):
        if path.is_file():
            assert path.suffix.lower() not in forbidden, path


def test_evidence_uses_conservative_statuses():
    report = _read("docs/architecture/PHASE4_SECURITY_REPORT.md")
    assert "PARTIAL" in report
    assert "NOT_PROVEN" in report
    assert "PRODUCTION" in report or "production" in report
