"""Canonical typed contracts for the Phase 5 agent runtime.

These contracts contain no model, memory, or security authority. They describe
transient execution state and delegate those authorities to the central runtime.
"""
from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Awaitable, Callable, Dict, List, Mapping, Optional


class TaskStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    WAITING_TOOL = "waiting_tool"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class PlanStep:
    objective: str
    action: str
    step_id: str = field(default_factory=lambda: f"step_{uuid.uuid4().hex[:10]}")
    dependencies: List[str] = field(default_factory=list)
    status: TaskStatus = TaskStatus.PENDING
    timeout_seconds: float = 30.0
    result: Any = None
    error: Optional[str] = None


@dataclass
class ExecutionPlan:
    goal: str
    steps: List[PlanStep]
    plan_id: str = field(default_factory=lambda: f"plan_{uuid.uuid4().hex[:12]}")
    max_steps: int = 10
    created_at: float = field(default_factory=time.time)


@dataclass
class Observation:
    tool_name: str
    execution_id: str
    status: TaskStatus
    output: Any = None
    error: Optional[str] = None
    started_at: float = field(default_factory=time.time)
    finished_at: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def duration_ms(self) -> Optional[float]:
        if self.finished_at is None:
            return None
        return round((self.finished_at - self.started_at) * 1000, 2)


@dataclass
class AgentExecutionContext:
    goal: str
    session_id: str
    task_id: str = field(default_factory=lambda: f"task_{uuid.uuid4().hex[:12]}")
    status: TaskStatus = TaskStatus.PENDING
    plan: Optional[ExecutionPlan] = None
    observations: List[Observation] = field(default_factory=list)
    transient_state: Dict[str, Any] = field(default_factory=dict)
    started_at: float = field(default_factory=time.time)
    max_steps: int = 10
    execution_timeout_seconds: float = 120.0

    @property
    def steps_completed(self) -> int:
        return sum(1 for item in self.plan.steps if item.status == TaskStatus.COMPLETED) if self.plan else 0


ToolHandler = Callable[..., Any]


@dataclass(frozen=True)
class ToolSpec:
    name: str
    description: str
    input_schema: Mapping[str, Any]
    output_schema: Mapping[str, Any]
    capabilities: frozenset[str] = frozenset()
    permissions: frozenset[str] = frozenset()
    timeout_seconds: float = 30.0
    dangerous: bool = False
    idempotent: bool = False
    handler: ToolHandler = field(repr=False, compare=False, default=lambda **_: None)


@dataclass(frozen=True)
class ToolCall:
    tool_name: str
    arguments: Mapping[str, Any]
    execution_id: str = field(default_factory=lambda: f"exec_{uuid.uuid4().hex[:12]}")
    idempotency_key: Optional[str] = None


@dataclass
class AgentTraceEvent:
    event: str
    task_id: str
    timestamp: float = field(default_factory=time.time)
    data: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AgentRunResult:
    success: bool
    output: Any
    context: AgentExecutionContext
    events: List[AgentTraceEvent] = field(default_factory=list)
    error: Optional[str] = None


PermissionChecker = Callable[[ToolSpec, Mapping[str, Any]], Awaitable[bool] | bool]
