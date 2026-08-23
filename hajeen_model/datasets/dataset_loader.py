from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Iterable, List


class DatasetLoader:
    """Small compatibility adapter for the historical Hajeen dataset contract.

    The adapter deliberately performs local JSONL loading and formatting only;
    versioning and persistence remain owned by DatasetManager.
    """

    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)

    def load_jsonl(self) -> List[Dict[str, Any]]:
        with self.path.open(encoding="utf-8") as handle:
            return [json.loads(line) for line in handle if line.strip()]

    @staticmethod
    def _as_chat(sample: Dict[str, Any]) -> Dict[str, Any]:
        messages = sample.get("messages")
        if isinstance(messages, list):
            return {"messages": messages}
        instruction = str(sample.get("instruction", ""))
        user_input = str(sample.get("input", ""))
        output = str(sample.get("output", ""))
        prompt = instruction if not user_input else f"{instruction}\n{user_input}"
        return {
            "messages": [
                {"role": "user", "content": prompt},
                {"role": "assistant", "content": output},
            ]
        }

    @staticmethod
    def _is_alpaca(sample: Dict[str, Any]) -> bool:
        return all(key in sample for key in ("instruction", "output"))

    def format_for_training(
        self, data: Iterable[Dict[str, Any]], format_type: str = "chat"
    ) -> List[Dict[str, Any]]:
        rows = list(data)
        if format_type == "alpaca":
            return [row for row in rows if self._is_alpaca(row)]
        if format_type == "chat":
            return [self._as_chat(row) for row in rows]
        raise ValueError("format_type must be 'alpaca' or 'chat'")

    @staticmethod
    def get_statistics(data: Iterable[Dict[str, Any]]) -> Dict[str, int]:
        rows = list(data)
        return {"total_samples": len(rows)}
