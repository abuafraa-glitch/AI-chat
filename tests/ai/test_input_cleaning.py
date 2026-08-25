from __future__ import annotations

import json
from pathlib import Path

import pytest

from brain.clean_data_store import CleanConversationStore
from brain.input_cleaning import clean_model_output, clean_user_input


def test_clean_user_input_preserves_arabic_and_removes_markup() -> None:
    raw = "  <b>مرحباً</b>\u200b   بالعالم\r\n\r\n\r\n  "
    result = clean_user_input(raw)

    assert result.clean_text == "مرحباً بالعالم"
    assert result.raw_sha256 != result.clean_sha256
    assert "html_text_extraction" in result.transformations
    assert result.metadata()["raw_text_persisted"] is False


@pytest.mark.asyncio
async def test_store_contains_clean_text_only(tmp_path: Path) -> None:
    cleaned = clean_user_input("<script>alert(1)</script>  سؤال عربي")
    store = CleanConversationStore(tmp_path)
    path = Path(await store.save_user_message(
        request_id="req-clean-1",
        session_id="session-1",
        user_id=None,
        cleaned=cleaned,
    ))

    assert path.exists()
    payload = json.loads(path.read_text(encoding="utf-8"))
    assert payload["text"] == "سؤال عربي"
    assert "alert(1)" not in payload["text"]
    assert "raw_text" not in payload
    assert "<script>" not in json.dumps(payload, ensure_ascii=False)
    assert "alert(1)" not in json.dumps(payload, ensure_ascii=False)
    assert payload["metadata"]["raw_sha256"] == cleaned.raw_sha256


@pytest.mark.asyncio
async def test_store_model_output_is_separate_and_clean(tmp_path: Path) -> None:
    cleaned = clean_model_output("  <b>إجابة</b>\n\n\n آمنة  ")
    store = CleanConversationStore(tmp_path)
    path = Path(await store.save_model_output(
        request_id="req-clean-output-1",
        session_id="session-1",
        user_id="user-1",
        cleaned=cleaned,
        provider="groq",
        model_id="test-model",
    ))

    payload = json.loads(path.read_text(encoding="utf-8"))
    assert payload["record_type"] == "model_output"
    assert payload["text"] == "إجابة\n\nآمنة"
    assert payload["metadata"]["provider"] == "groq"
    assert payload["metadata"]["raw_text_persisted"] is False
    assert "raw_text" not in payload


def test_model_output_cleaning_preserves_arabic_and_removes_unsafe_markup() -> None:
    result = clean_model_output("<script>secret()</script>  النتيجة: <i>نعم</i>")
    assert result.clean_text == "النتيجة: نعم"
    assert "script" in result.transformations[0] or "unsafe_html_block_removal" in result.transformations
    assert result.metadata()["raw_text_persisted"] is False


def test_empty_input_is_rejected() -> None:
    with pytest.raises(ValueError):
        clean_user_input(" \u200b\n ")



def test_streaming_output_cleaner_holds_and_removes_split_unsafe_markup() -> None:
    from brain.input_cleaning import StreamingOutputCleaner

    cleaner = StreamingOutputCleaner(holdback_chars=64)
    emitted = cleaner.feed("بداية <scr")
    emitted += cleaner.feed("ipt>alert('x')</scr")
    emitted += cleaner.feed("ipt> نهاية آمنة")
    emitted += cleaner.finish()

    assert "alert" not in emitted
    assert "<script" not in emitted.lower()
    assert "نهاية آمنة" in emitted


def test_streaming_output_cleaner_rejects_use_after_finish() -> None:
    from brain.input_cleaning import StreamingOutputCleaner

    cleaner = StreamingOutputCleaner(holdback_chars=64)
    cleaner.finish()
    with pytest.raises(RuntimeError):
        cleaner.feed("بعد الإنهاء")


@pytest.mark.asyncio
async def test_model_output_metadata_preserves_source_separation(tmp_path: Path) -> None:
    cleaned = clean_model_output("إجابة صالحة")
    path = Path(await CleanConversationStore(tmp_path).save_model_output(
        request_id="training-test",
        session_id="session-test",
        user_id=None,
        cleaned=cleaned,
        provider="local-test",
        model_id="deterministic-test",
    ))
    payload = json.loads(path.read_text(encoding="utf-8"))
    assert payload["text"] == "إجابة صالحة"
    assert payload["metadata"]["provider"] == "local-test"
    assert payload["metadata"]["model_id"] == "deterministic-test"
    assert payload["metadata"]["raw_text_persisted"] is False
