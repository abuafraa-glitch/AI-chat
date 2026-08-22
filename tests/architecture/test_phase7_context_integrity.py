import pytest

from security.runtime_admission import AdmissionDenied, ExecutionContext


def context(**overrides):
    values = {
        "request_id": "req-1",
        "user_id": "user-1",
        "tenant_id": "tenant-a",
        "conversation_id": "conv-1",
        "model_id": "model-a",
    }
    values.update(overrides)
    return ExecutionContext(**values)


def test_context_contains_required_trace_fields():
    current = context()
    assert current.request_id == "req-1"
    assert current.user_id == "user-1"
    assert current.tenant_id == "tenant-a"
    assert current.conversation_id == "conv-1"
    assert current.model_id == "model-a"


def test_missing_context_field_is_fail_closed():
    with pytest.raises(AdmissionDenied, match="missing_execution_context:tenant_id"):
        context(tenant_id="")


def test_client_cannot_override_authenticated_tenant():
    with pytest.raises(AdmissionDenied, match="tenant_context_tampering"):
        context().assert_client_tenant("tenant-b")


def test_same_tenant_client_claim_is_accepted():
    context().assert_client_tenant("tenant-a")
