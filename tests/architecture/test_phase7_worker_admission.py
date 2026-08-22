import pytest

from security.runtime_admission import (
    AdmissionDenied,
    ExecutionContext,
    TaskEnvelope,
    admit_worker_execution,
)


def make_envelope(**overrides):
    values = {
        "context": ExecutionContext("req-1", "user-1", "tenant-a", "conv-1", "model-a"),
        "authorized": True,
        "model_verified": True,
        "provider_allowed": True,
        "provider_name": "native",
        "authorization_context": True,
    }
    values.update(overrides)
    return TaskEnvelope(**values)


def test_worker_admission_accepts_complete_envelope():
    events = []
    admitted = admit_worker_execution(make_envelope(), audit=lambda name, _: events.append(name))
    assert admitted.tenant_id == "tenant-a"
    assert events == ["worker_admitted"]


@pytest.mark.parametrize(
    ("field", "reason"),
    [
        ("authorization_context", "authorization_context_missing"),
        ("authorized", "task_not_authorized"),
        ("model_verified", "model_not_verified"),
        ("provider_allowed", "provider_not_admitted"),
    ],
)
def test_worker_admission_rejects_missing_security_fact(field, reason):
    with pytest.raises(AdmissionDenied, match=reason):
        admit_worker_execution(make_envelope(**{field: False}))


def test_test_provider_is_rejected_in_production():
    with pytest.raises(AdmissionDenied, match="test_provider_forbidden_in_production"):
        admit_worker_execution(make_envelope(provider_name="test"), production=True)


def test_worker_context_mismatch_is_rejected():
    expected = ExecutionContext("req-1", "user-1", "tenant-a", "conv-1", "model-a")
    actual = ExecutionContext("req-1", "user-1", "tenant-b", "conv-1", "model-a")
    with pytest.raises(AdmissionDenied, match="context_mismatch"):
        admit_worker_execution(make_envelope(context=actual), expected=expected)
