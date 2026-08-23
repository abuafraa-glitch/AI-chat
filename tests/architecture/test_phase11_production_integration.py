"""Phase 11 production-integration evidence.

The fixtures are local, file-backed SQLite and fakeredis-compatible Redis. They
exercise the existing isolation and runtime-admission contracts rather than
claiming that a mock is production infrastructure.
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

import pytest

from multi_tenant.isolation import TenantAwareQuery, tenant_context
from security.runtime_admission import (
    AdmissionDenied,
    ExecutionContext,
    TaskEnvelope,
    admit_worker_execution,
    authorize_stream,
)


class SQLiteTenantAdapter:
    def __init__(self, path: Path) -> None:
        self.connection = sqlite3.connect(path)
        self.connection.row_factory = sqlite3.Row
        self.connection.execute(
            "CREATE TABLE records (id TEXT PRIMARY KEY, tenant_id TEXT NOT NULL, value TEXT)"
        )
        self.connection.executemany(
            "INSERT INTO records (id, tenant_id, value) VALUES (?, ?, ?)",
            [("a-1", "tenant-a", "A"), ("b-1", "tenant-b", "B")],
        )
        self.connection.commit()

    def fetchall(self, query: str, params: tuple = ()):
        return [dict(row) for row in self.connection.execute(query.replace("%s", "?"), params)]

    def close(self) -> None:
        self.connection.close()


def test_persisted_reads_are_tenant_isolated(tmp_path: Path) -> None:
    adapter = SQLiteTenantAdapter(tmp_path / "tenant.sqlite3")
    try:
        query = TenantAwareQuery(adapter)
        with tenant_context("tenant-a", "user-a"):
            rows_a = query.fetchall("SELECT id, tenant_id, value FROM records")
        with tenant_context("tenant-b", "user-b"):
            rows_b = query.fetchall("SELECT id, tenant_id, value FROM records")
        assert rows_a == [{"id": "a-1", "tenant_id": "tenant-a", "value": "A"}]
        assert rows_b == [{"id": "b-1", "tenant_id": "tenant-b", "value": "B"}]
    finally:
        adapter.close()


def test_persisted_read_without_context_fails_closed(tmp_path: Path) -> None:
    adapter = SQLiteTenantAdapter(tmp_path / "tenant.sqlite3")
    try:
        with pytest.raises(RuntimeError, match="No tenant context"):
            TenantAwareQuery(adapter).fetchall("SELECT id FROM records")
    finally:
        adapter.close()


def test_worker_context_survives_serializable_envelope_and_rejects_mismatch() -> None:
    context = ExecutionContext("req-11", "user-a", "tenant-a", "conv-a", "model-a")
    envelope = TaskEnvelope(
        context=context,
        authorized=True,
        model_verified=True,
        provider_allowed=True,
        provider_name="native",
        authorization_context=True,
    )
    restored = TaskEnvelope.from_mapping(
        {
            "context": {
                "request_id": context.request_id,
                "user_id": context.user_id,
                "tenant_id": context.tenant_id,
                "conversation_id": context.conversation_id,
                "model_id": context.model_id,
            },
            "authorized": True,
            "model_verified": True,
            "provider_allowed": True,
            "provider_name": "native",
            "authorization_context": True,
        }
    )
    assert admit_worker_execution(restored) == context
    wrong = ExecutionContext("req-11", "user-a", "tenant-b", "conv-a", "model-a")
    with pytest.raises(AdmissionDenied, match="context_mismatch"):
        admit_worker_execution(
            TaskEnvelope(
                context=wrong,
                authorized=True,
                model_verified=True,
                provider_allowed=True,
                provider_name="native",
                authorization_context=True,
            ),
            expected=context,
        )


def test_stream_gate_rejects_cross_tenant_before_first_event() -> None:
    context = ExecutionContext("req-12", "user-a", "tenant-a", "conv-a", "model-a")
    with pytest.raises(AdmissionDenied, match="cross_tenant_stream_denied"):
        authorize_stream(
            context,
            conversation_tenant_id="tenant-b",
            model_verified=True,
            provider_available=True,
            authorized=True,
        )


def test_stream_gate_rejects_unverified_model_fail_closed() -> None:
    context = ExecutionContext("req-13", "user-a", "tenant-a", "conv-a", "model-a")
    with pytest.raises(AdmissionDenied, match="stream_model_not_verified"):
        authorize_stream(
            context,
            conversation_tenant_id="tenant-a",
            model_verified=False,
            provider_available=True,
            authorized=True,
        )
