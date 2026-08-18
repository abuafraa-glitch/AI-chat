from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple


class DatasetManager:
    def __init__(self, storage_dir: str = "data/datasets", **_: Any) -> None:
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)

    def load_data(self, path: str) -> List[Dict[str, Any]]:
        with open(path, encoding="utf-8") as handle:
            return [json.loads(line) for line in handle if line.strip()]

    def merge_datasets(self, datasets: Iterable[Iterable[Dict[str, Any]]]) -> List[Dict[str, Any]]:
        return [item for dataset in datasets for item in dataset]

    def split_dataset(self, data: List[Dict[str, Any]], train_ratio: float = 0.9) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
        if not 0 < train_ratio < 1:
            raise ValueError("train_ratio must be between 0 and 1")
        cut = int(len(data) * train_ratio)
        return data[:cut], data[cut:]

    def perform_quality_check(self, data: Iterable[Dict[str, Any]], min_quality_score: float = 0) -> List[Dict[str, Any]]:
        return [row for row in data if sum(bool(v) for v in row.values()) >= min_quality_score]

    def process_and_version(self, data: List[Dict[str, Any]], version: str) -> str:
        target = self.storage_dir / version
        target.mkdir(parents=True, exist_ok=True)
        output = target / "data.jsonl"
        with output.open("w", encoding="utf-8") as handle:
            for row in data:
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")
        return str(target)

    def get_statistics(self, version: str) -> Dict[str, Any]:
        target = self.storage_dir / version / "data.jsonl"
        rows = self.load_data(str(target)) if target.exists() else []
        return {"num_samples": len(rows), "version": version}

    def list_versions(self) -> List[str]:
        return sorted(path.name for path in self.storage_dir.iterdir() if path.is_dir())
