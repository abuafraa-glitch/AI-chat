"""Local dataset validation contract for Phase 12 readiness checks."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import List


@dataclass
class DatasetReport:
    valid_lines: int = 0
    invalid_lines: int = 0
    issues: List[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return self.valid_lines > 0 and not self.issues


class DatasetValidator:
    def __init__(self, min_lines: int = 1, min_chars: int = 1) -> None:
        self.min_lines = min_lines
        self.min_chars = min_chars

    def validate_file(self, path: str) -> DatasetReport:
        report = DatasetReport()
        file_path = Path(path)
        if not file_path.is_file():
            report.issues.append(f"file_not_found:{path}")
            return report
        for line_no, line in enumerate(file_path.read_text(encoding="utf-8").splitlines(), 1):
            if len(line.strip()) >= self.min_chars:
                report.valid_lines += 1
            elif line.strip():
                report.invalid_lines += 1
                report.issues.append(f"line_too_short:{line_no}")
        if report.valid_lines < self.min_lines:
            report.issues.append(f"not_enough_lines:{report.valid_lines}/{self.min_lines}")
        return report
