"""تنظيف مدخلات ومخرجات المحادثة قبل استخدامها داخلياً أو تخزينها."""
from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import html
import re
import unicodedata
from typing import Any, Dict

try:
    from bs4 import BeautifulSoup
except Exception:  # pragma: no cover
    BeautifulSoup = None

_ZERO_WIDTH_RE = re.compile(r"[\u200b\u200c\u200d\u2060\ufeff]")
_CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
_SPACE_RE = re.compile(r"[ \t\r\f\v]+")
_NEWLINE_RE = re.compile(r"\n{3,}")
_TAG_RE = re.compile(r"<[^>]*>")
_UNSAFE_BLOCK_RE = re.compile(
    r"<\s*(script|style)\b[^>]*>.*?<\s*/\s*\1\s*>",
    flags=re.IGNORECASE | re.DOTALL,
)


@dataclass(frozen=True)
class CleanedInput:
    """نص منظف مع بصمات تحقق؛ لا يعيد النص الخام ولا يحفظه."""

    clean_text: str
    raw_sha256: str
    clean_sha256: str
    original_length: int
    cleaned_length: int
    transformations: tuple[str, ...] = field(default_factory=tuple)

    def metadata(self) -> Dict[str, Any]:
        return {
            "cleaning_version": "1.1.0",
            "raw_sha256": self.raw_sha256,
            "clean_sha256": self.clean_sha256,
            "original_length": self.original_length,
            "cleaned_length": self.cleaned_length,
            "transformations": list(self.transformations),
            "raw_text_persisted": False,
        }


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _normalize(raw_text: str, *, max_chars: int, extract_html: bool) -> CleanedInput:
    if not isinstance(raw_text, str):
        raise TypeError("text must be a string")
    if not raw_text.strip():
        raise ValueError("text must not be empty")

    original_length = len(raw_text)
    value = unicodedata.normalize("NFC", raw_text)
    transformations: list[str] = []
    if value != raw_text:
        transformations.append("unicode_nfc")

    unescaped = html.unescape(value)
    if unescaped != value:
        transformations.append("html_unescape")
    value = unescaped

    value, removed_blocks = _UNSAFE_BLOCK_RE.subn(" ", value)
    if removed_blocks:
        transformations.append("unsafe_html_block_removal")

    if extract_html and "<" in value and ">" in value:
        if BeautifulSoup is not None:
            value = BeautifulSoup(value, "html.parser").get_text(" ")
        else:
            value = _TAG_RE.sub(" ", value)
        transformations.append("html_text_extraction")
    elif not extract_html and "<" in value and ">" in value:
        value = _TAG_RE.sub(" ", value)
        transformations.append("html_tag_removal")

    value = _ZERO_WIDTH_RE.sub("", value)
    value = _CONTROL_RE.sub("", value)
    value = value.replace("\r\n", "\n").replace("\r", "\n")
    value = _SPACE_RE.sub(" ", value)
    value = _NEWLINE_RE.sub("\n\n", value)
    value = "\n".join(line.strip() for line in value.split("\n"))
    value = value.strip()
    if len(value) > max_chars:
        value = value[:max_chars].rstrip()
        transformations.append(f"max_chars_{max_chars}")
    if not value:
        raise ValueError("text is empty after cleaning")
    if value != raw_text:
        transformations.append("whitespace_and_control_cleanup")

    return CleanedInput(
        clean_text=value,
        raw_sha256=_sha256(raw_text),
        clean_sha256=_sha256(value),
        original_length=original_length,
        cleaned_length=len(value),
        transformations=tuple(dict.fromkeys(transformations)),
    )


def clean_user_input(raw_text: str, *, max_chars: int = 32_000) -> CleanedInput:
    """تنظيف رسالة المستخدم قبل Policy وIntent وRAG وModelRouter."""
    return _normalize(raw_text, max_chars=max_chars, extract_html=True)


def clean_model_output(raw_text: str, *, max_chars: int = 64_000) -> CleanedInput:
    """تنظيف إجابة النموذج الخام قبل الذاكرة والتخزين وإعادتها للعميل."""
    return _normalize(raw_text, max_chars=max_chars, extract_html=False)


class StreamingOutputCleaner:
    """منظف متدفق يحجز ذيل النص حتى تكتمل وسوم HTML أو أنماط الحظر."""

    def __init__(self, *, holdback_chars: int = 512) -> None:
        if holdback_chars < 64:
            raise ValueError("holdback_chars must be at least 64")
        self.holdback_chars = holdback_chars
        self._buffer = ""
        self._finished = False

    def feed(self, delta: str) -> str:
        if self._finished:
            raise RuntimeError("stream cleaner already finished")
        if not isinstance(delta, str):
            raise TypeError("stream delta must be a string")
        self._buffer += delta
        if len(self._buffer) <= self.holdback_chars:
            return ""
        candidate_end = len(self._buffer) - self.holdback_chars
        # لا نقطع داخل وسم قد يكون بدأ في نهاية الجزء القابل للإرسال.
        last_open = self._buffer.rfind("<", 0, candidate_end)
        last_close = self._buffer.rfind(">", 0, candidate_end)
        if last_open > last_close:
            candidate_end = last_open
        if candidate_end <= 0:
            return ""
        candidate = self._buffer[:candidate_end]
        self._buffer = self._buffer[candidate_end:]
        return clean_model_output(candidate).clean_text

    def finish(self) -> str:
        if self._finished:
            return ""
        self._finished = True
        remaining = self._buffer
        self._buffer = ""
        if not remaining.strip():
            return ""
        return clean_model_output(remaining).clean_text


def clean_assistant_output(raw_text: str, *, max_chars: int = 64_000) -> CleanedInput:
    """اسم دلالي لطبقة تنظيف رد المساعد."""
    return clean_model_output(raw_text, max_chars=max_chars)
