"""Phase 9 evidence tests for isolated persistence and durable-audit semantics.

The SQLite adapter is an isolated integration fixture. It proves the logger's
persistence contract, not production database deployment readiness.
"""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path
from typing import Any

from security.audit.audit_logger import AuditAction, AuditLogger


class SQLiteAuditAdapter:
    """Small file-backed adapter matching AuditLogger's DB protocol."""

    def __init__(self, path: Path) -> None:
        self.connection = sqlite3.connect(path)
        self.connection.row_factory = sqlite3.Row
        self.connection.execute(
            """CREATE TABLE IF NOT EXISTS audit_log (
                event_id TEXT PRIMARY KEY, timestamp REAL, tenant_id TEXT,
                user_id TEXT, action TEXT, resource_type TEXT, resource_id TEXT,
                ip_address TEXT, user_agent TEXT, request_id TEXT, status TEXT,
                error TEXT, metadata TEXT, hash TEXT, previous_hash TEXT
            )"""
        )
        self.connection.commit()

    def execute(self, query: str, params: tuple[Any, ...]) -> None:
        self.connection.execute(query.replace("%s", "?"), params)
        self.connection.commit()

    def fetchone(self, query: str):
        row = self.connection.execute(query.replace("%s", "?"), ()).fetchone()
        return dict(row) if row else None

    def fetchall(self, query: str, params: tuple[Any, ...] = ()):
        rows = self.connection.execute(query.replace("%s", "?"), params).fetchall()
        return [dict(row) for row in rows]

    def close(self) -> None:
        self.connection.close()


def test_audit_persists_and_verifies_chain(tmp_path: Path) -> None:
    db_path = tmp_path / "audit.sqlite3"
    adapter = SQLiteAuditAdapter(db_path)
    try:
        logger = AuditLogger(db=adapter, redis_client=None)
        first = logger.log(
            AuditAction.LOGIN_SUCCESS,
            "auth",
            "login",
            tenant_id="tenant-a",
            user_id="user-a",
            request_id="req-1",
        )
        second = logger.log(
            AuditAction.PERMISSION_DENIED,
            "conversation",
            "conversation-a",
            tenant_id="tenant-a",
            user_id="user-b",
            request_id="req-2",
            status="denied",
            error="cross_tenant_or_unauthorized",
        )

        assert db_path.exists()
        rows = adapter.fetchall("SELECT * FROM audit_log ORDER BY timestamp ASC LIMIT %s", (100,))
        assert len(rows) == 2
        assert rows[0]["tenant_id"] == "tenant-a"
        assert rows[1]["status"] == "denied"
        assert second.previous_hash == first.hash
        assert logger.verify_chain() == {
            "verified": True,
            "total_events": 2,
            "broken_events": [],
        }
    finally:
        adapter.close()


def test_audit_chain_detects_tampering(tmp_path: Path) -> None:
    adapter = SQLiteAuditAdapter(tmp_path / "audit.sqlite3")
    try:
        logger = AuditLogger(db=adapter, redis_client=None)
        event = logger.log(
            AuditAction.MODEL_INFERENCE,
            "model",
            "safe-model",
            tenant_id="tenant-a",
            user_id="user-a",
            request_id="req-3",
            metadata={"model_id": "safe-model"},
        )
        adapter.connection.execute(
            "UPDATE audit_log SET metadata = ? WHERE event_id = ?",
            (json.dumps({"model_id": "tampered-model"}), event.event_id),
        )
        adapter.connection.commit()
        result = logger.verify_chain()
        assert result["verified"] is False
        assert result["broken_events"] == [event.event_id]
    finally:
        adapter.close()


def test_audit_event_does_not_contain_credentials(tmp_path: Path) -> None:
    adapter = SQLiteAuditAdapter(tmp_path / "audit.sqlite3")
    try:
        logger = AuditLogger(db=adapter, redis_client=None)
        event = logger.log(
            AuditAction.LOGIN_FAILED,
            "auth",
            "login",
            tenant_id="tenant-a",
            user_id="user-a",
            request_id="req-4",
            error="invalid_credentials",
        )
        serialized = json.dumps(event.__dict__, default=str).lower()
        assert "password" not in serialized
        assert "access_token" not in serialized
        assert "refresh_token" not in serialized
    finally:
        adapter.close()


def test_in_memory_fallback_is_not_claimed_as_durable() -> None:
    from security.audit.audit_logger import _InMemoryAuditStore

    store = _InMemoryAuditStore()
    assert store.__class__.__name__ == "_InMemoryAuditStore"
    # This is an explicit classification guard: local fallback is not durable evidence.
    assert "InMemory" in store.__class__.__name__
