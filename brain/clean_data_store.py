"""مخزن محلي للنسخ المنظفة فقط، مع منع حفظ النص الخام."""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
from typing import Any, Dict

from .input_cleaning import CleanedInput

_SAFE_ID = re.compile(r"[^a-zA-Z0-9_.-]+")


class CleanConversationStore:
    """يحفظ سجلات المنظف لا النصوص الخام، ويقسم الإدخال عن إخراج النموذج."""

    def __init__(self, base_dir: str | Path | None = None) -> None:
        configured = base_dir or os.getenv("HAJEEN_CLEAN_DATA_DIR")
        self.base_dir = Path(configured or Path(__file__).resolve().parents[1] / "storage_data" / "cleaned_conversations")

    def _path(self, request_id: str, record_type: str, now: datetime | None = None) -> Path:
        timestamp = now or datetime.now(timezone.utc)
        safe_id = _SAFE_ID.sub("_", request_id).strip("._") or "request"
        safe_type = _SAFE_ID.sub("_", record_type).strip("._") or "record"
        return self.base_dir / f"{timestamp.year:04d}" / f"{timestamp.month:02d}" / f"{timestamp.day:02d}" / f"{safe_id}.{safe_type}.json"

    async def _save(
        self,
        *,
        request_id: str,
        session_id: str,
        user_id: str | None,
        record_type: str,
        cleaned: CleanedInput,
        metadata: Dict[str, Any] | None = None,
    ) -> str:
        path = self._path(request_id, record_type)
        supplied = metadata or {}
        governed_metadata = {
            "source_type": "user" if record_type == "user_message" else "assistant_output",
            "provider": supplied.get("provider"),
            "model_id": supplied.get("model_id"),
            "quality_status": supplied.get("quality_status", "unreviewed"),
            "review_status": supplied.get("review_status", "pending"),
            "consent_status": supplied.get("consent_status", "not_recorded"),
            # لا تدخل البيانات التدريب قبل مراجعة صريحة وموافقة قابلة للتدقيق.
            "training_eligible": bool(supplied.get("training_eligible", False)),
            "training_exclusion_reason": supplied.get("training_exclusion_reason", "requires_review"),
        }
        governed_metadata.update(supplied)
        payload: Dict[str, Any] = {
            "schema": "hajeen.cleaned_conversation.v3",
            "record_type": record_type,
            "request_id": request_id,
            "session_id": session_id,
            "user_id": user_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "text": cleaned.clean_text,
            "metadata": {**cleaned.metadata(), **governed_metadata},
        }
        encoded = (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8")

        def write_atomic() -> None:
            path.parent.mkdir(parents=True, exist_ok=True)
            temporary = path.with_suffix(path.suffix + ".tmp")
            temporary.write_bytes(encoded)
            os.replace(temporary, path)

        await asyncio.to_thread(write_atomic)
        return str(path)

    async def save_user_message(self, *, request_id: str, session_id: str, user_id: str | None, cleaned: CleanedInput) -> str:
        return await self._save(request_id=request_id, session_id=session_id, user_id=user_id, record_type="user_message", cleaned=cleaned)

    async def save_model_output(self, *, request_id: str, session_id: str, user_id: str | None, cleaned: CleanedInput, provider: str | None = None, model_id: str | None = None) -> str:
        return await self._save(
            request_id=request_id,
            session_id=session_id,
            user_id=user_id,
            record_type="model_output",
            cleaned=cleaned,
            metadata={"provider": provider, "model_id": model_id},
        )
