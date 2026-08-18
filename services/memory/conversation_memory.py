"""
ConversationMemory — compatibility adapter over the unified MemoryFabric interface.

The adapter owns no persistence. Every read and write is routed through
UnifiedMemoryInterface, whose backing store is MemoryFabric.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from dataclasses import dataclass, field
from time import time
from typing import Any, Dict, List, Optional

from brain.memory.unified_interface import get_unified_memory

logger = logging.getLogger(__name__)


@dataclass
class Message:
    role: str
    content: str
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: float = field(default_factory=time)


def _run_sync(coro):
    """Run a memory coroutine without replacing the caller's event loop."""
    try:
        running = asyncio.get_running_loop()
    except RuntimeError:
        running = None
    if running is not None and running.is_running():
        raise RuntimeError("Synchronous memory API cannot run inside an active event loop")
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop.run_until_complete(coro)


class ConversationMemory:
    """Synchronous compatibility view backed exclusively by MemoryFabric."""

    def __init__(self, session_id: Optional[str] = None, max_messages: int = 20, **kwargs: Any):
        self.session_id = session_id or str(uuid.uuid4())
        self.max_messages = max_messages
        self._system_prompt: Optional[str] = None
        self._unified_memory = get_unified_memory()
        self._unified_memory._ensure_fabric()
        self._conversation = self._unified_memory._fabric.get_conversation(self.session_id)

    def add_user_message(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> Message:
        return self._add_sync("user", content, metadata)

    def add_assistant_message(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> Message:
        return self._add_sync("assistant", content, metadata)

    def _add_sync(self, role: str, content: str, metadata: Optional[Dict[str, Any]]) -> Message:
        message = Message(role=role, content=content, metadata=metadata or {})
        _run_sync(self._unified_memory.add_message(self.session_id, role, content, metadata))
        if len(self._conversation._messages) > self.max_messages:
            system = [m for m in self._conversation._messages if m.get("role") == "system"][:1]
            body = [m for m in self._conversation._messages if m.get("role") != "system"]
            self._conversation._messages[:] = system + body[-max(self.max_messages - len(system), 0):]
        return message

    def set_system_prompt(self, prompt: str) -> None:
        self._system_prompt = prompt
        self._conversation._messages[:] = [m for m in self._conversation._messages if m.get("role") != "system"]
        self._conversation._messages.insert(0, {"role": "system", "content": prompt, "metadata": {}, "at": time()})
        if len(self._conversation._messages) > self.max_messages:
            body = [m for m in self._conversation._messages if m.get("role") != "system"]
            self._conversation._messages[:] = [self._conversation._messages[0]] + body[-max(self.max_messages - 1, 0):]

    def get_system_prompt(self) -> Optional[str]:
        return self._system_prompt

    def _history(self, max_messages: int = 20) -> List[Dict[str, Any]]:
        return _run_sync(self._unified_memory.get_context(self.session_id, max_messages=max_messages))

    def get_messages(
        self,
        limit: Optional[int] = None,
        max_messages: Optional[int] = None,
        include_system: bool = True,
        max_tokens: Optional[int] = None,
        **kwargs: Any,
    ) -> List[Any]:
        from core.llm.base import LLMMessage

        requested = max_messages or limit or 20
        history = self._history(max_messages=max(requested, self.max_messages))
        if not include_system:
            history = [item for item in history if item.get("role") != "system"]
        messages = [LLMMessage(role=item["role"], content=item["content"]) for item in history]
        if max_tokens is not None:
            total = 0
            selected: List[Any] = []
            for message in reversed(messages):
                count = len(message.content.split())
                if selected and total + count > max_tokens:
                    break
                selected.append(message)
                total += count
            messages = list(reversed(selected))
        return messages

    def clear(self) -> None:
        _run_sync(self._unified_memory.clear_session(self.session_id))

    @property
    def message_count(self) -> int:
        return len(self._conversation._messages)

    @property
    def total_tokens(self) -> int:
        return sum(len(item.get("content", "").split()) for item in self._history(max_messages=100000))
