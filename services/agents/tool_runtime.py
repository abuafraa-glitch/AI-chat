"""Canonical tool registry and execution authority for Phase 5."""
from __future__ import annotations

import asyncio
import inspect
import time
from typing import Any, Dict, List, Mapping, Optional

from brain.policy.policy_engine import PolicyDecision, PolicyEngine

from .contracts import Observation, PermissionChecker, TaskStatus, ToolCall, ToolSpec


class ToolRegistry:
    """The single runtime catalogue of tools available to an agent task."""

    def __init__(self) -> None:
        self._specs: Dict[str, ToolSpec] = {}

    def register(self, spec: ToolSpec) -> None:
        if not spec.name.strip():
            raise ValueError("Tool name cannot be empty")
        if spec.timeout_seconds <= 0:
            raise ValueError("Tool timeout must be positive")
        if spec.name in self._specs:
            raise ValueError(f"Tool already registered: {spec.name}")
        self._specs[spec.name] = spec

    def get(self, name: str) -> Optional[ToolSpec]:
        return self._specs.get(name)

    def list(self) -> List[ToolSpec]:
        return list(self._specs.values())

    def describe(self) -> List[Dict[str, Any]]:
        return [
            {
                "name": item.name,
                "description": item.description,
                "input_schema": dict(item.input_schema),
                "output_schema": dict(item.output_schema),
                "capabilities": sorted(item.capabilities),
                "permissions": sorted(item.permissions),
                "timeout_seconds": item.timeout_seconds,
                "dangerous": item.dangerous,
                "idempotent": item.idempotent,
            }
            for item in self._specs.values()
        ]


class ToolExecutor:
    """Executes registered tools only after policy and permission checks."""

    def __init__(
        self,
        registry: ToolRegistry,
        policy_engine: PolicyEngine,
        permission_checker: Optional[PermissionChecker] = None,
    ) -> None:
        self.registry = registry
        self.policy_engine = policy_engine
        self.permission_checker = permission_checker
        self._completed_keys: Dict[str, Observation] = {}

    async def execute(
        self,
        call: ToolCall,
        *,
        session_id: str,
        user_id: Optional[str] = None,
        granted_permissions: frozenset[str] = frozenset(),
    ) -> Observation:
        spec = self.registry.get(call.tool_name)
        started = time.time()
        if spec is None:
            return Observation(
                tool_name=call.tool_name,
                execution_id=call.execution_id,
                status=TaskStatus.FAILED,
                error=f"Unknown tool: {call.tool_name}",
                started_at=started,
                finished_at=time.time(),
            )

        if call.idempotency_key and call.idempotency_key in self._completed_keys:
            previous = self._completed_keys[call.idempotency_key]
            return Observation(
                tool_name=spec.name,
                execution_id=call.execution_id,
                status=previous.status,
                output=previous.output,
                error=previous.error,
                started_at=started,
                finished_at=time.time(),
                metadata={"idempotent_replay": True, "original_execution_id": previous.execution_id},
            )

        if spec.dangerous and not spec.permissions.issubset(granted_permissions):
            return Observation(
                tool_name=spec.name,
                execution_id=call.execution_id,
                status=TaskStatus.FAILED,
                error="Tool permission denied",
                started_at=started,
                finished_at=time.time(),
                metadata={"security": "denied", "required_permissions": sorted(spec.permissions)},
            )

        policy = await self.policy_engine.evaluate({
            "query": f"tool:{spec.name}",
            "tool_name": spec.name,
            "capabilities": sorted(spec.capabilities),
            "permissions": sorted(spec.permissions),
            "session_id": session_id,
            "user_id": user_id,
        })
        if policy.final_decision == PolicyDecision.BLOCK or policy.blocked:
            return Observation(
                tool_name=spec.name,
                execution_id=call.execution_id,
                status=TaskStatus.FAILED,
                error=policy.reason if hasattr(policy, "reason") else "Tool blocked by policy",
                started_at=started,
                finished_at=time.time(),
                metadata={"security": "policy_denied", "policy": policy.to_dict()},
            )

        if self.permission_checker is not None:
            allowed = self.permission_checker(spec, {"session_id": session_id, "user_id": user_id, "arguments": dict(call.arguments)})
            if inspect.isawaitable(allowed):
                allowed = await allowed
            if not allowed:
                return Observation(
                    tool_name=spec.name,
                    execution_id=call.execution_id,
                    status=TaskStatus.FAILED,
                    error="Tool permission denied",
                    started_at=started,
                    finished_at=time.time(),
                    metadata={"security": "permission_denied"},
                )

        try:
            result = spec.handler(**dict(call.arguments))
            if inspect.isawaitable(result):
                result = await asyncio.wait_for(result, timeout=spec.timeout_seconds)
            else:
                result = await asyncio.wait_for(asyncio.to_thread(lambda: result), timeout=spec.timeout_seconds)
            observation = Observation(
                tool_name=spec.name,
                execution_id=call.execution_id,
                status=TaskStatus.COMPLETED,
                output=result,
                started_at=started,
                finished_at=time.time(),
                metadata={"policy": policy.to_dict()},
            )
            if call.idempotency_key:
                self._completed_keys[call.idempotency_key] = observation
            return observation
        except asyncio.CancelledError:
            raise
        except asyncio.TimeoutError:
            return Observation(
                tool_name=spec.name,
                execution_id=call.execution_id,
                status=TaskStatus.FAILED,
                error=f"Tool timeout after {spec.timeout_seconds}s",
                started_at=started,
                finished_at=time.time(),
                metadata={"timeout": True},
            )
        except Exception as exc:
            return Observation(
                tool_name=spec.name,
                execution_id=call.execution_id,
                status=TaskStatus.FAILED,
                error=str(exc),
                started_at=started,
                finished_at=time.time(),
            )
