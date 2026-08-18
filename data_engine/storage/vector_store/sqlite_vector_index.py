from __future__ import annotations

import json
import math
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional

from .base_vector_store import BaseVectorStore, SearchResult, VectorEntry, VectorStoreStats


class SQLiteVectorIndex(BaseVectorStore):
    def __init__(self, db_path: str, dimensions: Optional[int] = None) -> None:
        self.db_path = str(db_path)
        self.dimensions = dimensions or 0
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as db:
            db.execute("CREATE TABLE IF NOT EXISTS vectors (id TEXT PRIMARY KEY, vector TEXT NOT NULL, chunk_id TEXT NOT NULL, article_id TEXT NOT NULL, text TEXT, model_name TEXT, metadata TEXT)")

    def _connect(self):
        return sqlite3.connect(self.db_path)

    def add(self, entries: List[VectorEntry]) -> int:
        with self._connect() as db:
            for entry in entries:
                self.dimensions = self.dimensions or len(entry.vector)
                if len(entry.vector) != self.dimensions:
                    raise ValueError("Vector dimensions do not match index dimensions")
                db.execute("INSERT OR REPLACE INTO vectors VALUES (?, ?, ?, ?, ?, ?, ?)", (entry.id, json.dumps(entry.vector), entry.chunk_id, entry.article_id, entry.text, entry.model_name, json.dumps(entry.metadata, ensure_ascii=False)))
        return len(entries)

    @staticmethod
    def _cosine(a: List[float], b: List[float]) -> float:
        denom = math.sqrt(sum(x*x for x in a)) * math.sqrt(sum(y*y for y in b))
        return sum(x*y for x, y in zip(a, b)) / denom if denom else 0.0

    def search(self, query_vector: List[float], top_k: int = 10, filter_metadata: Optional[Dict] = None) -> List[SearchResult]:
        if self.dimensions and len(query_vector) != self.dimensions:
            raise ValueError("Query dimensions do not match index dimensions")
        results: List[SearchResult] = []
        with self._connect() as db:
            rows = db.execute("SELECT vector, chunk_id, article_id, text, model_name, metadata FROM vectors").fetchall()
        for vector_json, chunk_id, article_id, text, model_name, metadata_json in rows:
            metadata = json.loads(metadata_json or "{}")
            if filter_metadata and any(metadata.get(k) != v for k, v in filter_metadata.items()):
                continue
            results.append(SearchResult(chunk_id=chunk_id, article_id=article_id, score=self._cosine(query_vector, json.loads(vector_json)), text=text or "", model_name=model_name or "", metadata=metadata))
        return sorted(results, key=lambda item: item.score, reverse=True)[:top_k]

    def delete(self, ids: List[str]) -> int:
        with self._connect() as db:
            cur = db.executemany("DELETE FROM vectors WHERE id = ?", [(item,) for item in ids])
            return cur.rowcount

    def stats(self) -> VectorStoreStats:
        with self._connect() as db:
            count = db.execute("SELECT COUNT(*) FROM vectors").fetchone()[0]
        return VectorStoreStats(total_vectors=count, index_type="sqlite", dimensions=self.dimensions, is_trained=True)

    def save(self, path: str) -> None:
        Path(path).write_bytes(Path(self.db_path).read_bytes())

    def load(self, path: str) -> None:
        Path(self.db_path).write_bytes(Path(path).read_bytes())
