"""Minimal tensor dataset contracts used by the historical Hajeen tests."""
from __future__ import annotations

from typing import Iterable, List, Sequence, Tuple

import torch
from torch.utils.data import Dataset


class HajeenDataset(Dataset):
    def __init__(self, samples: Iterable[Tuple[Sequence[int], Sequence[int]]]) -> None:
        self.samples = list(samples)

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, index: int):
        input_ids, labels = self.samples[index]
        return {"input_ids": torch.tensor(input_ids, dtype=torch.long), "labels": torch.tensor(labels, dtype=torch.long)}

    @staticmethod
    def collate_fn(batch: List[dict], pad_token_id: int = 0):
        max_len = max(item["input_ids"].numel() for item in batch)
        input_ids = torch.full((len(batch), max_len), pad_token_id, dtype=torch.long)
        labels = torch.full((len(batch), max_len), -100, dtype=torch.long)
        for row, item in enumerate(batch):
            length = item["input_ids"].numel()
            input_ids[row, :length] = item["input_ids"]
            labels[row, :item["labels"].numel()] = item["labels"]
        return {"input_ids": input_ids, "labels": labels}


class DatasetBuilder:
    def __init__(self, tokenizer=None, max_length: int = 2048) -> None:
        self.tokenizer = tokenizer
        self.max_length = max_length

    def build(self, rows: Iterable[dict]) -> HajeenDataset:
        if self.tokenizer is None:
            raise ValueError("tokenizer is required to build tokenized samples")
        samples = []
        for row in rows:
            text = row.get("text") or row.get("output") or ""
            ids = self.tokenizer.encode(text)[: self.max_length]
            samples.append((ids, ids.copy()))
        return HajeenDataset(samples)
