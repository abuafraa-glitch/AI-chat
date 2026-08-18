from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional


class EpisodicMemory:
    def __init__(self, storage_path: str = "storage_data/episodic_memory.jsonl") -> None:
        self.storage_path = Path(storage_path)
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        self.experiences: List[Dict[str, Any]] = []
        if self.storage_path.exists():
            for line in self.storage_path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    try:
                        self.experiences.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue

    def add_experience(self, prompt: str, actions: Any, outcome: Any, success: bool, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        record = {"prompt": prompt, "actions": actions, "outcome": outcome, "success": bool(success)}
        if metadata is not None:
            record["metadata"] = metadata
        self.experiences.append(record)
        with self.storage_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, ensure_ascii=False) + "\n")
        return record

    def retrieve_experiences(self, keyword: str) -> List[Dict[str, Any]]:
        needle = keyword.casefold()
        return [e for e in reversed(self.experiences) if needle in json.dumps(e, ensure_ascii=False).casefold()]

    def get_successful_experiences(self) -> List[Dict[str, Any]]:
        return [e for e in reversed(self.experiences) if e.get("success") is True]

    def get_failed_experiences(self) -> List[Dict[str, Any]]:
        return [e for e in reversed(self.experiences) if e.get("success") is False]
