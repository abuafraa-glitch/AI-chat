"""Phase 8.3 — Stream Handler: إدارة streaming responses."""
from __future__ import annotations

import asyncio
import logging
import time
from dataclasses import dataclass, field
from typing import Any, AsyncGenerator, Dict, List, Optional

from core.llm.base import LLMStreamChunk

logger = logging.getLogger(__name__)


@dataclass
class StreamSession:
    """جلسة streaming نشطة."""
    session_id: str
    started_at: float = field(default_factory=time.time)
    chunks_received: int = 0
    total_chars: int = 0
    cancelled: bool = False
    completed: bool = False
    error: Optional[str] = None

    def add_chunk(self, delta: str) -> None:
        self.chunks_received += 1
        self.total_chars += len(delta)

    @property
    def duration_ms(self) -> float:
        return (time.time() - self.started_at) * 1000


@dataclass
class StreamEvent:
    """حدث SSE."""
    event_type: str  # "token" | "done" | "error"
    data: str
    chunk_index: int = 0
    finish_reason: Optional[str] = None

    def to_sse(self) -> str:
        """تحويل إلى Server-Sent Event format."""
        lines = [f"event: {self.event_type}"]
        lines.append(f"data: {self.data}")
        lines.append("")  # blank line
        return "\n".join(lines) + "\n"

    def to_dict(self) -> dict:
        return {
            "type": self.event_type,
            "data": self.data,
            "index": self.chunk_index,
            "finish_reason": self.finish_reason,
        }


class StreamHandler:
    """
    إدارة streaming responses.

    المهام:
    - تتبع جلسات streaming
    - تحويل chunks لـ SSE events
    - دعم إلغاء الطلبات
    - تجميع الـ chunks في buffer
    - معالجة انقطاع الاتصال
    """

    def __init__(
        self,
        buffer_size: int = 10,
        chunk_timeout: float = 30.0,
    ):
        self._sessions: Dict[str, StreamSession] = {}
        self.buffer_size = buffer_size
        self.chunk_timeout = chunk_timeout

    def create_session(self, session_id: str) -> StreamSession:
        session = StreamSession(session_id=session_id)
        self._sessions[session_id] = session
        return session

    def get_session(self, session_id: str) -> Optional[StreamSession]:
        return self._sessions.get(session_id)

    def cancel_session(self, session_id: str) -> bool:
        session = self._sessions.get(session_id)
        if session:
            session.cancelled = True
            logger.info("Stream session cancelled: %s", session_id)
            return True
        return False

    def cleanup_session(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)

    async def process_stream(
        self,
        chunk_generator: AsyncGenerator[LLMStreamChunk, None],
        session_id: str,
    ) -> AsyncGenerator[LLMStreamChunk, None]:
        """تمرير native chunks مع التتبع والإلغاء دون تصنيع أحداث أو نصوص."""
        session = self.create_session(session_id)
        saw_finish = False
        index = 0

        try:
            yield LLMStreamChunk(
                delta="",
                event_type="start",
                index=index,
                request_id=session_id,
                metadata={"session_id": session_id},
            )
            async for chunk in chunk_generator:
                if not isinstance(chunk, LLMStreamChunk):
                    raise RuntimeError("Stream provider returned a non-native chunk")
                if session.cancelled:
                    logger.info("Stream %s: cancelled by client", session_id)
                    session.error = "cancelled"
                    yield LLMStreamChunk(
                        delta="",
                        event_type="error",
                        index=index,
                        request_id=session_id,
                        metadata={"error": "Stream cancelled"},
                    )
                    return

                if chunk.delta:
                    session.add_chunk(chunk.delta)
                index = max(index, chunk.index)
                if chunk.event_type == "finish":
                    saw_finish = True
                    session.completed = True
                elif chunk.event_type == "error":
                    session.error = chunk.metadata.get("error", "stream failed")
                yield chunk
                if chunk.finish_reason and chunk.event_type != "finish":
                    saw_finish = True
                    session.completed = True
                    yield LLMStreamChunk(
                        delta="",
                        finish_reason=chunk.finish_reason,
                        event_type="finish",
                        index=index + 1,
                        model=chunk.model,
                        provider=chunk.provider,
                        request_id=chunk.request_id or session_id,
                        metadata=dict(chunk.metadata),
                    )

            if not saw_finish and session.error is None:
                session.error = "Stream ended without finish event"
                yield LLMStreamChunk(
                    delta="",
                    event_type="error",
                    index=index + 1,
                    request_id=session_id,
                    metadata={"error": session.error},
                )

        except asyncio.CancelledError:
            session.error = "cancelled"
            raise
        except Exception as e:
            session.error = str(e)
            logger.error("Stream %s error: %s", session_id, e)
            yield LLMStreamChunk(
                delta="",
                event_type="error",
                index=index,
                request_id=session_id,
                metadata={"error": str(e)},
            )
        finally:
            logger.debug(
                "Stream %s ended: chunks=%d chars=%d ms=%.1f",
                session_id,
                session.chunks_received,
                session.total_chars,
                session.duration_ms,
            )
            self.cleanup_session(session_id)

    async def collect_full_response(
        self,
        chunk_generator: AsyncGenerator[LLMStreamChunk, None],
    ) -> str:
        """جمع streaming response في نص كامل."""
        parts = []
        async for chunk in chunk_generator:
            if chunk.delta:
                parts.append(chunk.delta)
        return "".join(parts)
