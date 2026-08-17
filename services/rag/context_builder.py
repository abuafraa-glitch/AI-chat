"""Context Builder — يبني context من chunks متعددة."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

from services.retrieval.context_assembler import AssembledContext


@dataclass
class BuiltContext:
    """Context مبني وجاهز للـ prompt، ويدعم أيضاً واجهة النص القديمة."""
    raw_chunks: List[Dict]
    formatted_text: str
    sources: List[str]
    total_chars: int
    total_tokens_estimate: int
    metadata: Dict = field(default_factory=dict)

    def __str__(self) -> str:
        return self.formatted_text

    def __len__(self) -> int:
        return len(self.formatted_text)

    def __contains__(self, item: str) -> bool:
        return item in self.formatted_text

    def __eq__(self, other: object) -> bool:
        if isinstance(other, str):
            return self.formatted_text == other
        return super().__eq__(other)


class ContextBuilder:
    """
    يحوّل AssembledContext إلى context منسّق للـ prompt.
    يدعم:
    - تحديد الحد الأقصى للـ tokens
    - تنسيق مع أو بدون أرقام المصادر
    - window truncation
    """

    def __init__(
        self,
        max_tokens: int = 2000,
        context_style: str = "numbered",
        max_context_chars: Optional[int] = None,
    ):
        self.max_tokens = max_tokens
        self.context_style = context_style
        self.max_context_chars = max_context_chars

    def build(self, assembled, query: Optional[str] = None) -> BuiltContext:
        """Build from AssembledContext or the legacy list of retrieval results."""
        if isinstance(assembled, (list, tuple)):
            raw_input = list(assembled)
            chunks = []
            sources = []
            metadata = {}
            for item in raw_input:
                if hasattr(item, "to_dict"):
                    item = item.to_dict()
                elif hasattr(item, "content"):
                    item = {"id": getattr(item, "doc_id", ""), "text": item.content, "score": getattr(item, "score", 0.0), "metadata": getattr(item, "metadata", {})}
                item = dict(item)
                if "text" not in item and "content" in item:
                    item["text"] = item["content"]
                chunks.append(item)
                source = item.get("metadata", {}).get("source")
                if source:
                    sources.append(source)
        else:
            raw_input = assembled
            chunks = list(getattr(assembled, "chunks", []) or [])
            sources = list(getattr(assembled, "sources", []) or [])
            metadata = dict(getattr(assembled, "metadata", {}) or {})

        lines = []
        used_tokens = 0
        raw_chunks = []
        used_chars = 0
        for i, chunk in enumerate(chunks, 1):
            text = chunk.get("text", chunk.get("content", "")).strip()
            if not text:
                continue
            token_est = len(text.split())
            if used_tokens + token_est > self.max_tokens:
                break
            candidate = f"[{i}] {text}" if self.context_style == "numbered" else text
            if self.max_context_chars is not None and used_chars + len(candidate) + (2 if lines else 0) > self.max_context_chars:
                remaining = self.max_context_chars - used_chars - (2 if lines else 0)
                if remaining <= 0:
                    break
                candidate = candidate[:remaining]
            lines.append(candidate)
            raw_chunks.append(chunk)
            used_tokens += token_est
            used_chars += len(candidate) + (2 if len(lines) > 1 else 0)
            if self.max_context_chars is not None and used_chars >= self.max_context_chars:
                break

        formatted = "\n\n".join(lines)
        return BuiltContext(raw_chunks=raw_chunks, formatted_text=formatted, sources=sources, total_chars=len(formatted), total_tokens_estimate=used_tokens, metadata=metadata)
