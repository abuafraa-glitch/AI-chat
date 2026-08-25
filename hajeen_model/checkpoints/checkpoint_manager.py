from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any, Optional

import torch


class CheckpointManager:
    def __init__(self, root_dir: str, keep_n: int = 3):
        self.root_dir = Path(root_dir)
        self.directory = self.root_dir / "checkpoints"
        self.keep_n = max(1, int(keep_n))
        self.directory.mkdir(parents=True, exist_ok=True)

    def _path(self, step: int) -> Path:
        return self.directory / f"step_{int(step):09d}"

    def _saved_steps(self) -> list[int]:
        steps = []
        for p in self.directory.glob("step_*"):
            try:
                steps.append(int(p.name.split("_")[-1]))
            except ValueError:
                continue
        return sorted(steps)

    def save(self, model, optimizer=None, step: int = 0, metrics: Optional[dict[str, Any]] = None):
        path = self._path(step)
        path.mkdir(parents=True, exist_ok=True)
        torch.save(model.state_dict(), path / "model.pt")
        if optimizer is not None:
            torch.save(optimizer.state_dict(), path / "optimizer.pt")
        meta = {"step": int(step), "metrics": metrics or {}}
        (path / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
        for old_step in self._saved_steps()[:-self.keep_n]:
            shutil.rmtree(self._path(old_step), ignore_errors=True)
        return str(path)

    def load(self, model, step: int, optimizer=None):
        path = self._path(step)
        if not (path / "model.pt").exists():
            return None
        model.load_state_dict(torch.load(path / "model.pt", map_location="cpu", weights_only=True))
        if optimizer is not None and (path / "optimizer.pt").exists():
            optimizer.load_state_dict(torch.load(path / "optimizer.pt", map_location="cpu", weights_only=True))
        return json.loads((path / "meta.json").read_text(encoding="utf-8"))

    def load_latest(self, model, optimizer=None):
        steps = self._saved_steps()
        return self.load(model, steps[-1], optimizer=optimizer) if steps else None

    def list_checkpoints(self):
        result = []
        for step in self._saved_steps():
            meta_path = self._path(step) / "meta.json"
            result.append(json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {"step": step})
        return result
