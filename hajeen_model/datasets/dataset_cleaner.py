"""Compatibility adapter for the historical DatasetCleaner import.

The canonical dataset cleaner is not present as source in this checkout; this
adapter intentionally exposes the tested contract without touching legacy
files elsewhere in the repository.
"""
from __future__ import annotations

import re
import unicodedata
from pathlib import Path
from typing import Iterable, List, Optional


class DatasetCleaner:
    def __init__(self, min_chars: int = 1, max_chars: Optional[int] = None,
                 remove_html: bool = False, remove_diacritics: bool = False,
                 deduplicate: bool = False) -> None:
        self.min_chars = min_chars
        self.max_chars = max_chars
        self.remove_html = remove_html
        self.remove_diacritics = remove_diacritics
        self.deduplicate = deduplicate

    def clean(self, text: str) -> Optional[str]:
        if not isinstance(text, str):
            return None
        result = text.strip()
        if self.remove_html:
            result = re.sub(r"<[^>]+>", "", result)
        if self.remove_diacritics:
            result = "".join(ch for ch in unicodedata.normalize("NFD", result)
                             if unicodedata.category(ch) != "Mn")
        result = result.strip()
        if len(result) < self.min_chars:
            return None
        if self.max_chars is not None and len(result) > self.max_chars:
            return None
        return result

    def clean_batch(self, texts: Iterable[str]) -> List[str]:
        output: List[str] = []
        seen = set()
        for text in texts:
            cleaned = self.clean(text)
            if cleaned is None or (self.deduplicate and cleaned in seen):
                continue
            seen.add(cleaned)
            output.append(cleaned)
        return output

    def clean_file(self, input_path: str, output_path: str) -> None:
        lines = Path(input_path).read_text(encoding="utf-8").splitlines()
        cleaned = self.clean_batch(lines)
        Path(output_path).write_text("\n".join(cleaned) + ("\n" if cleaned else ""), encoding="utf-8")
