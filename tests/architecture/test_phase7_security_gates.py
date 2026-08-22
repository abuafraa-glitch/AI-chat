from pathlib import Path

import pytest

from security.runtime_admission import AdmissionDenied, ExecutionContext, authorize_stream

ROOT = Path(__file__).resolve().parents[2]
PRODUCTION_DIRS = (ROOT / "api", ROOT / "services", ROOT / "brain")
FORBIDDEN_IMPORT_MARKERS = (
    "from openai import",
    "from anthropic import",
    "import openai",
    "import anthropic",
)


def production_python_files():
    for directory in PRODUCTION_DIRS:
        if directory.exists():
            yield from directory.rglob("*.py")


def test_production_layers_do_not_import_known_provider_sdks_directly():
    violations = []
    for path in production_python_files():
        text = path.read_text(encoding="utf-8")
        for marker in FORBIDDEN_IMPORT_MARKERS:
            if marker in text:
                violations.append(f"{path.relative_to(ROOT)}:{marker}")
    assert not violations, "direct provider imports: " + "; ".join(violations)


def test_unknown_or_unverified_stream_fails_closed():
    context = ExecutionContext("req", "user", "tenant", "conversation", "model")
    with pytest.raises(AdmissionDenied):
        authorize_stream(
            context,
            conversation_tenant_id="tenant",
            model_verified=False,
            provider_available=True,
            authorized=True,
        )


def test_unauthorized_stream_fails_before_provider_access():
    context = ExecutionContext("req", "user", "tenant", "conversation", "model")
    with pytest.raises(AdmissionDenied, match="stream_not_authorized"):
        authorize_stream(
            context,
            conversation_tenant_id="tenant",
            model_verified=True,
            provider_available=True,
            authorized=False,
        )
