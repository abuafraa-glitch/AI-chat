"""Fail-closed runtime admission contracts for API and worker boundaries.

This module is intentionally small and side-effect free. It does not replace
ModelRegistry or ProviderRegistry; it validates the context and admission
facts that must be supplied by those canonical boundaries before execution.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Mapping, Optional


class AdmissionDenied(PermissionError):
    """Raised whenever execution cannot be proven safe."""


@dataclass(frozen=True)
class ExecutionContext:
    request_id: str
    user_id: str
    tenant_id: str
    conversation_id: str
    model_id: str

    def __post_init__(self) -> None:
        fields = {
            "request_id": self.request_id,
            "user_id": self.user_id,
            "tenant_id": self.tenant_id,
            "conversation_id": self.conversation_id,
            "model_id": self.model_id,
        }
        missing = [name for name, value in fields.items() if not isinstance(value, str) or not value.strip()]
        if missing:
            raise AdmissionDenied(f"missing_execution_context:{','.join(missing)}")

    @classmethod
    def from_mapping(cls, values: Mapping[str, Any]) -> "ExecutionContext":
        return cls(
            request_id=values.get("request_id", ""),
            user_id=values.get("user_id", ""),
            tenant_id=values.get("tenant_id", ""),
            conversation_id=values.get("conversation_id", ""),
            model_id=values.get("model_id", ""),
        )

    def assert_client_tenant(self, client_tenant_id: Optional[str] = None) -> None:
        if client_tenant_id is not None and client_tenant_id != self.tenant_id:
            raise AdmissionDenied("tenant_context_tampering")


@dataclass(frozen=True)
class TaskEnvelope:
    context: ExecutionContext
    authorized: bool
    model_verified: bool
    provider_allowed: bool
    provider_name: str
    authorization_context: bool = True

    @classmethod
    def from_mapping(cls, values: Mapping[str, Any]) -> "TaskEnvelope":
        context = ExecutionContext.from_mapping(values.get("context", values))
        return cls(
            context=context,
            authorized=bool(values.get("authorized", False)),
            model_verified=bool(values.get("model_verified", False)),
            provider_allowed=bool(values.get("provider_allowed", False)),
            provider_name=str(values.get("provider_name", "")),
            authorization_context=bool(values.get("authorization_context", False)),
        )


def admit_worker_execution(
    envelope: TaskEnvelope,
    *,
    expected: Optional[ExecutionContext] = None,
    production: bool = True,
    audit: Optional[Callable[[str, TaskEnvelope], None]] = None,
) -> ExecutionContext:
    """Admit a worker task only when every security precondition is explicit."""
    def deny(reason: str) -> None:
        if audit is not None:
            audit(reason, envelope)
        raise AdmissionDenied(reason)

    if expected is not None and envelope.context != expected:
        deny("context_mismatch")
    if not envelope.authorization_context:
        deny("authorization_context_missing")
    if not envelope.authorized:
        deny("task_not_authorized")
    if not envelope.context.model_id:
        deny("model_id_missing")
    if not envelope.model_verified:
        deny("model_not_verified")
    if production and envelope.provider_name.lower() == "test":
        deny("test_provider_forbidden_in_production")
    if not envelope.provider_allowed:
        deny("provider_not_admitted")
    if audit is not None:
        audit("worker_admitted", envelope)
    return envelope.context


def authorize_stream(
    context: ExecutionContext,
    *,
    conversation_tenant_id: str,
    model_verified: bool,
    provider_available: bool,
    authorized: bool,
) -> None:
    """Authorize a stream before its first event is emitted."""
    if not authorized:
        raise AdmissionDenied("stream_not_authorized")
    if context.tenant_id != conversation_tenant_id:
        raise AdmissionDenied("cross_tenant_stream_denied")
    if not model_verified:
        raise AdmissionDenied("stream_model_not_verified")
    if not provider_available:
        raise AdmissionDenied("stream_provider_unavailable")
