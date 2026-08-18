"""Canonical, evidence-backed self-evolution lifecycle.

This module orchestrates injected real executors and existing Phase 6 authorities.
It never fabricates experiment/evaluation results and never mutates production
without explicit evaluation, policy approval, versioning, staging and deployment
hooks.
"""
from __future__ import annotations

import asyncio
import inspect
import time
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Awaitable, Callable, Dict, Mapping, Optional


class EvolutionLifecycleError(RuntimeError):
    pass


class EvolutionState(str, Enum):
    OBSERVED = "OBSERVED"
    HYPOTHESIS = "HYPOTHESIS"
    HYPOTHESIS_CREATED = "HYPOTHESIS_CREATED"
    EXPERIMENT_PLANNED = "EXPERIMENT_PLANNED"
    EXPERIMENTING = "EXPERIMENT_RUNNING"
    EXPERIMENT_RUNNING = "EXPERIMENT_RUNNING"
    EXPERIMENT_COMPLETED = "EXPERIMENT_COMPLETED"
    REFLECTED = "REFLECTED"
    EVALUATING = "EVALUATING"
    EVALUATED = "EVALUATED"
    APPROVAL_PENDING = "APPROVAL_PENDING"
    APPROVED = "APPROVED"
    VERSIONED = "VERSIONED"
    STAGED = "STAGED"
    DEPLOYING = "DEPLOYING"
    DEPLOYED = "DEPLOYED"
    MONITORING = "MONITORING"
    REJECTED = "REJECTED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    BLOCKED = "BLOCKED"
    ROLLED_BACK = "ROLLED_BACK"


@dataclass(frozen=True)
class EvolutionObservation:
    observation_id: str
    source: str
    payload: Mapping[str, Any]
    evidence_refs: tuple[str, ...] = ()
    created_at: float = field(default_factory=time.time)
    provenance: Mapping[str, Any] = field(default_factory=dict)
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class EvolutionHypothesis:
    hypothesis_id: str
    observation_id: str
    statement: str
    expected_metrics: Mapping[str, float]
    baseline: Mapping[str, float] = field(default_factory=dict)
    proposed_change: Mapping[str, Any] = field(default_factory=dict)
    risk: str = "medium"
    rollback_strategy: str = "restore_previous_valid_version"
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class ExperimentPlan:
    experiment_id: str
    hypothesis_id: str
    baseline_ref: Optional[str] = None
    candidate_ref: Optional[str] = None
    dataset_ref: Optional[str] = None
    benchmark_ref: Optional[str] = None
    configuration: Mapping[str, Any] = field(default_factory=dict)
    metrics: tuple[str, ...] = ()
    thresholds: Mapping[str, float] = field(default_factory=dict)
    timeout_seconds: float = 30.0
    resource_limits: Mapping[str, Any] = field(default_factory=dict)
    rollback_criteria: Mapping[str, Any] = field(default_factory=dict)
    isolated: bool = True


@dataclass(frozen=True)
class ExperimentResult:
    experiment_id: str
    hypothesis_id: str
    metrics: Mapping[str, float]
    observations: Mapping[str, Any]
    executor_id: str
    started_at: float
    completed_at: float
    evidence_refs: tuple[str, ...] = ()
    baseline_metrics: Mapping[str, float] = field(default_factory=dict)
    candidate_metrics: Mapping[str, float] = field(default_factory=dict)
    resource_usage: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class EvaluationResult:
    evaluation_id: str
    experiment_id: str
    metrics: Mapping[str, Any]
    passes_threshold: bool
    baseline_metrics: Mapping[str, Any] = field(default_factory=dict)
    candidate_metrics: Mapping[str, Any] = field(default_factory=dict)
    benchmark_ref: Optional[str] = None
    provenance: Mapping[str, Any] = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class ApprovalDecision:
    decision_id: str
    experiment_id: str
    status: str
    candidate_ref: str
    reason: str
    policy_version: Optional[str] = None
    metrics: Mapping[str, Any] = field(default_factory=dict)
    decided_by: str = "policy"
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class ImprovementCandidate:
    candidate_id: str
    candidate_ref: str
    experiment_id: str
    evaluation_id: str
    artifact_ref: Optional[str] = None
    configuration: Mapping[str, Any] = field(default_factory=dict)
    provenance: Mapping[str, Any] = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class EvolutionVersion:
    version_id: str
    candidate_ref: str
    experiment_id: str
    evaluation_id: str
    candidate_id: Optional[str] = None
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class DeploymentRecord:
    deployment_id: str
    experiment_id: str
    version_id: str
    deployment_ref: str
    status: str
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class RollbackRecord:
    rollback_id: str
    experiment_id: str
    deployment_ref: str
    status: str
    reason: str = ""
    created_at: float = field(default_factory=time.time)


@dataclass(frozen=True)
class EvolutionTrace:
    experiment_id: str
    state: EvolutionState
    event: str
    at: float = field(default_factory=time.time)
    details: Mapping[str, Any] = field(default_factory=dict)


@dataclass
class EvolutionRecord:
    experiment_id: str
    observation: EvolutionObservation
    hypothesis: EvolutionHypothesis
    plan: ExperimentPlan
    state: EvolutionState = EvolutionState.HYPOTHESIS
    result: Optional[ExperimentResult] = None
    reflection: Optional[Mapping[str, Any]] = None
    evaluation: Optional[Mapping[str, Any]] = None
    evaluation_result: Optional[EvaluationResult] = None
    candidate_ref: Optional[str] = None
    version: Optional[EvolutionVersion] = None
    candidate: Optional[ImprovementCandidate] = None
    approval: Optional[ApprovalDecision] = None
    deployment: Optional[DeploymentRecord] = None
    rollback: Optional[RollbackRecord] = None
    deployment_ref: Optional[str] = None
    error: Optional[str] = None
    trace: list[EvolutionTrace] = field(default_factory=list)


Executor = Callable[[EvolutionHypothesis, asyncio.Event], Awaitable[Mapping[str, Any]] | Mapping[str, Any]]
Reflector = Callable[[EvolutionRecord], Awaitable[Mapping[str, Any]] | Mapping[str, Any]]
Evaluator = Callable[[EvolutionRecord], Awaitable[Mapping[str, Any]] | Mapping[str, Any]]
Policy = Callable[[str, Mapping[str, Any]], Awaitable[bool] | bool]
Deployer = Callable[[EvolutionRecord], Awaitable[str] | str]
Rollbacker = Callable[[str], Awaitable[None] | None]


class EvolutionLifecycle:
    """Single authority for controlled, isolated and evidence-backed evolution."""

    def __init__(self, *, memory: Any, executor: Optional[Executor] = None,
                 reflector: Optional[Reflector] = None, evaluator: Optional[Evaluator] = None,
                 policy: Optional[Policy] = None, deployer: Optional[Deployer] = None,
                 rollbacker: Optional[Rollbacker] = None, timeout_seconds: float = 30.0,
                 phase6_coordinator: Any = None, model_registry: Any = None) -> None:
        if memory is None:
            raise ValueError("MemoryFabric is required")
        if timeout_seconds <= 0:
            raise ValueError("timeout_seconds must be positive")
        self.memory = memory
        self.executor, self.reflector, self.evaluator = executor, reflector, evaluator
        self.policy, self.deployer, self.rollbacker = policy, deployer, rollbacker
        self.timeout_seconds = timeout_seconds
        self.phase6_coordinator = phase6_coordinator
        self.model_registry = model_registry
        self._records: Dict[str, EvolutionRecord] = {}
        self._idempotency: Dict[str, str] = {}
        self._deployment_idempotency: Dict[str, str] = {}
        self._locks: Dict[str, asyncio.Lock] = {}
        self._cancel: Dict[str, asyncio.Event] = {}
        self._approval_idempotency: Dict[str, str] = {}
        self._version_idempotency: Dict[str, str] = {}

    def _lock_for(self, key: str) -> asyncio.Lock:
        return self._locks.setdefault(key, asyncio.Lock())

    def _event(self, record: EvolutionRecord, event: str, **details: Any) -> None:
        record.trace.append(EvolutionTrace(record.experiment_id, record.state, event, details=details))

    def _memory(self, record: EvolutionRecord, outcome: str) -> None:
        metadata = {"experiment_id": record.experiment_id, "state": record.state.value, "outcome": outcome}
        if hasattr(self.memory, "record_evolution_event"):
            self.memory.record_evolution_event("lifecycle", record.hypothesis.statement, outcome, metadata)
            return
        if hasattr(self.memory, "record_episode"):
            try:
                self.memory.record_episode("self_evolution", record.hypothesis.statement, outcome, metadata)
            except TypeError:
                # Backward-compatible test/double API; canonical MemoryFabric accepts metadata.
                self.memory.record_episode("self_evolution", record.hypothesis.statement, outcome)
        if hasattr(self.memory, "memorize_semantically"):
            self.memory.memorize_semantically(f"evolution:{record.experiment_id}:{outcome}", metadata)

    async def _call(self, fn: Callable[..., Any], *args: Any) -> Any:
        value = fn(*args)
        return await asyncio.wait_for(value, timeout=self.timeout_seconds) if inspect.isawaitable(value) else value

    def observe(self, source: str, payload: Mapping[str, Any], *, evidence_refs: tuple[str, ...] = (),
                hypothesis: Optional[str] = None, expected_metrics: Optional[Mapping[str, float]] = None,
                baseline: Optional[Mapping[str, float]] = None, proposed_change: Optional[Mapping[str, Any]] = None,
                dataset_ref: Optional[str] = None, benchmark_ref: Optional[str] = None,
                thresholds: Optional[Mapping[str, float]] = None, idempotency_key: Optional[str] = None) -> EvolutionRecord:
        if not source or not payload:
            raise ValueError("observation source and payload are required")
        if evidence_refs and any(not isinstance(ref, str) or not ref.strip() for ref in evidence_refs):
            raise ValueError("evidence_refs must contain non-empty strings")
        if idempotency_key and idempotency_key in self._idempotency:
            return self._records[self._idempotency[idempotency_key]]
        forbidden_keys = {"production_config", "production_database", "production_model", "secret", "secrets", "shell", "arbitrary_code", "unrestricted_network"}
        if forbidden_keys.intersection(payload) or forbidden_keys.intersection((proposed_change or {})):
            raise EvolutionLifecycleError("unsafe experiment capability requested")
        statement = hypothesis or str(payload.get("hypothesis", ""))
        if not statement:
            raise EvolutionLifecycleError("hypothesis is required; no implicit hypothesis is allowed")
        metrics = dict(expected_metrics or payload.get("expected_metrics", {}))
        observation = EvolutionObservation(str(uuid.uuid4()), source, dict(payload), evidence_refs,
                                           provenance={"source": source}, metadata={"evidence_only": True})
        item = EvolutionHypothesis(str(uuid.uuid4()), observation.observation_id, statement, metrics,
                                   dict(baseline or payload.get("baseline", {})),
                                   dict(proposed_change or payload.get("proposed_change", {})))
        experiment_id = str(uuid.uuid4())
        plan = ExperimentPlan(experiment_id, item.hypothesis_id, dataset_ref=dataset_ref,
                              benchmark_ref=benchmark_ref, metrics=tuple(metrics),
                              thresholds=dict(thresholds or metrics), timeout_seconds=self.timeout_seconds)
        if not plan.isolated:
            raise EvolutionLifecycleError("experiments must be isolated")
        record = EvolutionRecord(experiment_id, observation, item, plan)
        self._event(record, "observation_recorded", source=source)
        self._event(record, "hypothesis_created", hypothesis_id=item.hypothesis_id)
        self._event(record, "experiment_planned", isolated=plan.isolated)
        self._records[experiment_id] = record
        if idempotency_key:
            self._idempotency[idempotency_key] = experiment_id
        self._memory(record, "hypothesis_created")
        return record

    def create_hypothesis(self, experiment_id: str, *, statement: str,
                          expected_metrics: Mapping[str, float],
                          proposed_change: Optional[Mapping[str, Any]] = None) -> EvolutionHypothesis:
        """Return a typed hypothesis only for an existing evidence record."""
        record = self._require(experiment_id)
        if record.observation is None or not statement or not expected_metrics:
            raise EvolutionLifecycleError("evidence-backed measurable hypothesis is required")
        hypothesis = EvolutionHypothesis(
            record.hypothesis.hypothesis_id,
            record.observation.observation_id,
            statement,
            dict(expected_metrics),
            dict(record.hypothesis.baseline),
            dict(proposed_change or record.hypothesis.proposed_change),
            record.hypothesis.risk,
            record.hypothesis.rollback_strategy,
        )
        record.hypothesis = hypothesis
        self._event(record, "hypothesis_updated", hypothesis_id=hypothesis.hypothesis_id)
        return hypothesis

    def plan_experiment(self, experiment_id: str) -> ExperimentPlan:
        """Expose the immutable, isolated plan without executing it."""
        record = self._require(experiment_id)
        if not record.plan.isolated:
            raise EvolutionLifecycleError("experiment isolation is mandatory")
        return record.plan

    async def run_experiment(self, experiment_id: str) -> EvolutionRecord:
        record = self._require(experiment_id)
        async with self._lock_for(experiment_id):
            if record.state in {EvolutionState.EXPERIMENT_COMPLETED, EvolutionState.REFLECTED, EvolutionState.EVALUATED, EvolutionState.APPROVED, EvolutionState.VERSIONED, EvolutionState.STAGED, EvolutionState.DEPLOYING, EvolutionState.DEPLOYED}:
                return record
            if self.executor is None:
                return self._fail(record, "real_experiment_executor_required")
            cancel = self._cancel.setdefault(experiment_id, asyncio.Event())
            record.state = EvolutionState.EXPERIMENTING
            self._event(record, "experiment_started", isolated=record.plan.isolated)
            started = time.time()
            try:
                raw = await self._call(self.executor, record.hypothesis, cancel)
                if cancel.is_set():
                    record.state = EvolutionState.CANCELLED
                    self._event(record, "experiment_cancelled")
                    self._memory(record, "cancelled")
                    raise asyncio.CancelledError
                if not isinstance(raw, Mapping) or not raw.get("metrics"):
                    return self._fail(record, "executor_returned_no_evidence")
                result = ExperimentResult(experiment_id, record.hypothesis.hypothesis_id, dict(raw["metrics"]),
                    dict(raw.get("observations", {})), str(raw.get("executor_id", "injected-executor")), started, time.time(),
                    tuple(raw.get("evidence_refs", ())), dict(raw.get("baseline_metrics", record.hypothesis.baseline)),
                    dict(raw.get("candidate_metrics", raw["metrics"])), dict(raw.get("resource_usage", {})))
                record.result = result
                record.state = EvolutionState.EXPERIMENT_COMPLETED
                self._event(record, "experiment_completed", metrics=dict(result.metrics), resource_usage=dict(result.resource_usage))
                self._memory(record, "experiment_completed")
                return record
            except asyncio.CancelledError:
                record.state = EvolutionState.CANCELLED
                self._event(record, "experiment_cancelled")
                self._memory(record, "cancelled")
                raise
            except asyncio.TimeoutError:
                return self._fail(record, "experiment_timeout")
            except Exception as exc:
                return self._fail(record, f"experiment_failed:{type(exc).__name__}")

    async def reflect_and_evaluate(self, experiment_id: str) -> EvolutionRecord:
        record = self._require(experiment_id)
        if record.state is not EvolutionState.EXPERIMENT_COMPLETED or record.result is None:
            raise EvolutionLifecycleError("completed experiment evidence is required")
        if self.reflector is None or self.evaluator is None:
            return self._fail(record, "reflector_and_evaluator_required")
        record.reflection = await self._call(self.reflector, record)
        if not isinstance(record.reflection, Mapping):
            return self._fail(record, "invalid_reflection")
        record.state = EvolutionState.REFLECTED
        self._event(record, "reflection_completed")
        record.state = EvolutionState.EVALUATING
        evaluation = await self._call(self.evaluator, record)
        if not isinstance(evaluation, Mapping) or not evaluation.get("metrics"):
            return self._fail(record, "invalid_evaluation")
        candidate = dict(evaluation["metrics"])
        baseline = dict(evaluation.get("baseline_metrics", record.result.baseline_metrics))
        required = set(record.plan.thresholds) | set(record.hypothesis.expected_metrics)
        if required and not required.issubset(candidate):
            return self._fail(record, "missing_metrics:" + ",".join(sorted(required - set(candidate))))
        passed = bool(evaluation.get("passes_threshold", False))
        if not passed:
            record.state = EvolutionState.REJECTED
            record.error = "evaluation_threshold_failed"
            self._event(record, "evaluation_rejected", metrics=candidate)
            self._memory(record, record.error)
            return record
        evaluation_id = str(evaluation.get("evaluation_id", uuid.uuid4()))
        result = EvaluationResult(evaluation_id, experiment_id, candidate, True, baseline,
                                  dict(evaluation.get("candidate_metrics", candidate)),
                                  evaluation.get("benchmark_ref", record.plan.benchmark_ref),
                                  dict(evaluation.get("provenance", {})))
        record.evaluation_result = result
        record.evaluation = dict(evaluation)
        record.state = EvolutionState.EVALUATED
        self._event(record, "evaluation_completed", metrics=candidate, benchmark_ref=result.benchmark_ref)
        self._memory(record, "evaluated")
        return record

    async def approve(self, experiment_id: str, *, candidate_ref: str) -> EvolutionRecord:
        record = self._require(experiment_id)
        if record.state is not EvolutionState.EVALUATED or not candidate_ref:
            raise EvolutionLifecycleError("evaluated record and candidate_ref are required")
        if self.policy is None:
            record.state = EvolutionState.BLOCKED
            record.error = "approval_policy_required"
            self._event(record, "approval_blocked", reason=record.error)
            self._memory(record, record.error)
            return record
        allowed = await self._call(self.policy, "approve_evolution", {"experiment_id": experiment_id, "candidate_ref": candidate_ref, "evaluation": record.evaluation})
        if not allowed:
            record.approval = ApprovalDecision(
                decision_id="approval-" + uuid.uuid4().hex,
                experiment_id=experiment_id,
                status="REJECTED",
                candidate_ref=candidate_ref,
                reason="approval_policy_denied",
                policy_version=str(record.plan.configuration.get("policy_version")) if record.plan.configuration.get("policy_version") else None,
                metrics=dict(record.evaluation_result.metrics if record.evaluation_result else {}),
            )
            record.state = EvolutionState.REJECTED
            record.error = "approval_policy_denied"
            self._event(record, "approval_rejected", candidate_ref=candidate_ref, approval_id=record.approval.decision_id)
            self._memory(record, record.error)
            return record
        if self.model_registry is not None:
            configuration = dict(record.plan.configuration)
            model_id = configuration.get("model_id")
            model_version = configuration.get("model_version")
            if not model_id or not model_version or record.evaluation_result is None:
                return self._fail(record, "model_registry_lineage_required")
            try:
                self.model_registry.mark_evaluated(
                    str(model_id), str(model_version),
                    record.evaluation_result.evaluation_id,
                    record.evaluation_result.metrics,
                    record.evaluation_result.passes_threshold,
                )
                self.model_registry.approve(str(model_id), str(model_version))
            except Exception as exc:
                return self._fail(record, f"model_registry_approval_failed:{type(exc).__name__}")

        record.candidate_ref = candidate_ref
        record.candidate = ImprovementCandidate(
            candidate_id="candidate-" + uuid.uuid4().hex,
            candidate_ref=candidate_ref,
            experiment_id=experiment_id,
            evaluation_id=record.evaluation_result.evaluation_id if record.evaluation_result else "",
            artifact_ref=record.plan.configuration.get("artifact_location"),
            configuration=dict(record.plan.configuration),
            provenance=dict(record.evaluation_result.provenance if record.evaluation_result else {}),
        )
        record.approval = ApprovalDecision(
            decision_id="approval-" + uuid.uuid4().hex,
            experiment_id=experiment_id,
            status="APPROVED",
            candidate_ref=candidate_ref,
            reason="policy_approved",
            policy_version=str(record.plan.configuration.get("policy_version")) if record.plan.configuration.get("policy_version") else None,
            metrics=dict(record.evaluation_result.metrics if record.evaluation_result else {}),
        )
        record.state = EvolutionState.APPROVED
        record.version = EvolutionVersion("evo-" + uuid.uuid4().hex, candidate_ref, experiment_id, record.evaluation_result.evaluation_id if record.evaluation_result else "", record.candidate.candidate_id)
        record.state = EvolutionState.VERSIONED
        self._event(record, "approval_granted", candidate_ref=candidate_ref, version_id=record.version.version_id, approval_id=record.approval.decision_id)
        self._memory(record, "approved")
        return record

    async def deploy(self, experiment_id: str, *, idempotency_key: Optional[str] = None) -> EvolutionRecord:
        record = self._require(experiment_id)
        if idempotency_key and idempotency_key in self._deployment_idempotency:
            return record
        if record.state not in {EvolutionState.VERSIONED, EvolutionState.APPROVED, EvolutionState.STAGED} or self.deployer is None:
            return self._fail(record, "versioned_candidate_and_deployer_required")
        record.state = EvolutionState.STAGED
        self._event(record, "staged", version_id=record.version.version_id if record.version else None)
        record.state = EvolutionState.DEPLOYING
        self._event(record, "deployment_started")
        try:
            record.deployment_ref = str(await self._call(self.deployer, record))
            record.deployment = DeploymentRecord(
                deployment_id="deployment-" + uuid.uuid4().hex,
                experiment_id=experiment_id,
                version_id=record.version.version_id if record.version else "",
                deployment_ref=record.deployment_ref,
                status="DEPLOYED",
            )
            record.state = EvolutionState.DEPLOYED
            if idempotency_key:
                self._deployment_idempotency[idempotency_key] = experiment_id
            self._event(record, "deployment_completed", deployment_ref=record.deployment_ref)
            self._memory(record, "deployed")
            return record
        except asyncio.CancelledError:
            record.state = EvolutionState.CANCELLED
            self._event(record, "deployment_cancelled")
            raise
        except Exception as exc:
            return self._fail(record, f"deployment_failed:{type(exc).__name__}")

    async def rollback(self, experiment_id: str) -> EvolutionRecord:
        record = self._require(experiment_id)
        if record.state not in {EvolutionState.DEPLOYED, EvolutionState.MONITORING} or self.rollbacker is None or not record.deployment_ref:
            return self._fail(record, "deployed_record_and_rollbacker_required")
        try:
            await self._call(self.rollbacker, record.deployment_ref)
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            return self._fail(record, f"rollback_failed:{type(exc).__name__}")
        record.rollback = RollbackRecord(
            rollback_id="rollback-" + uuid.uuid4().hex,
            experiment_id=experiment_id,
            deployment_ref=record.deployment_ref,
            status="ROLLED_BACK",
            reason="explicit_rollback",
        )
        record.state = EvolutionState.ROLLED_BACK
        self._event(record, "rollback_completed", deployment_ref=record.deployment_ref)
        self._memory(record, "rolled_back")
        return record

    async def monitor(self, experiment_id: str, metrics: Mapping[str, Any]) -> EvolutionRecord:
        """Record post-deployment monitoring evidence; it never deploys or mutates."""
        record = self._require(experiment_id)
        if record.state is not EvolutionState.DEPLOYED or not metrics:
            return self._fail(record, "deployed_record_and_monitoring_metrics_required")
        record.state = EvolutionState.MONITORING
        self._event(record, "monitoring_recorded", metrics=dict(metrics))
        self._memory(record, "monitoring")
        return record

    def cancel(self, experiment_id: str) -> None:
        record = self._require(experiment_id)
        self._cancel.setdefault(experiment_id, asyncio.Event()).set()
        if record.state in {EvolutionState.OBSERVED, EvolutionState.HYPOTHESIS, EvolutionState.EXPERIMENT_PLANNED}:
            record.state = EvolutionState.CANCELLED
            self._event(record, "cancel_requested")
            self._memory(record, "cancelled")

    def get(self, experiment_id: str) -> EvolutionRecord:
        return self._require(experiment_id)

    def _require(self, experiment_id: str) -> EvolutionRecord:
        if experiment_id not in self._records:
            raise KeyError(f"unknown evolution experiment: {experiment_id}")
        return self._records[experiment_id]

    def _fail(self, record: EvolutionRecord, reason: str) -> EvolutionRecord:
        record.state = EvolutionState.FAILED
        record.error = reason
        self._event(record, "failed", reason=reason)
        self._memory(record, reason)
        return record


def make_phase6_evaluator(phase6_coordinator: Any) -> Evaluator:
    """Build a strict Phase 7 evaluator backed by the Phase 6 authority.

    The experiment plan must provide real runtime configuration under
    ``plan.configuration``: model identity, artifact location, benchmark
    metadata/path, and an ``infer_and_measure`` callable.  Missing inputs or a
    blocked Phase 6 run are returned as non-evidence and therefore fail closed
    in ``reflect_and_evaluate``.
    """
    if phase6_coordinator is None:
        raise ValueError("phase6_coordinator is required")

    async def _evaluate(record: EvolutionRecord) -> Mapping[str, Any]:
        configuration = dict(record.plan.configuration)
        infer_and_measure = configuration.get("infer_and_measure")
        required = (
            "model_id", "model_version", "artifact_location",
            "benchmark_id", "benchmark_version",
        )
        if any(not configuration.get(key) for key in required) or not callable(infer_and_measure):
            return {"metrics": {}, "passes_threshold": False, "provenance": {"error": "phase6_evaluation_inputs_required"}}

        evaluation = phase6_coordinator.create_run(
            model_id=str(configuration["model_id"]),
            model_version=str(configuration["model_version"]),
            artifact_location=str(configuration["artifact_location"]),
            benchmark_id=str(configuration["benchmark_id"]),
            benchmark_version=str(configuration["benchmark_version"]),
            sample_count=int(configuration.get("sample_count", 0)),
            benchmark_path=str(configuration.get("benchmark_path", "")),
            benchmark_source=str(configuration.get("benchmark_source", "")),
            benchmark_split=str(configuration.get("benchmark_split", "test")),
        )
        status_value = getattr(getattr(evaluation, "status", None), "value", None)
        if status_value != "QUEUED":
            return {
                "metrics": {},
                "passes_threshold": False,
                "provenance": {"phase6_evaluation_id": evaluation.evaluation_id, "error": evaluation.error},
            }
        completed = phase6_coordinator.run(
            evaluation,
            infer_and_measure,
            thresholds=record.plan.thresholds,
        )
        return {
            "evaluation_id": completed.evaluation_id,
            "metrics": dict(completed.metrics),
            "baseline_metrics": dict(record.result.baseline_metrics if record.result else {}),
            "candidate_metrics": dict(completed.metrics),
            "passes_threshold": bool(completed.passes_threshold),
            "benchmark_ref": record.plan.benchmark_ref,
            "provenance": dict(completed.metric_provenance),
        }

    return _evaluate


EvolutionLifecycleCoordinator = EvolutionLifecycle

__all__ = [
    "EvolutionLifecycle", "EvolutionLifecycleCoordinator", "EvolutionLifecycleError",
    "EvolutionObservation", "EvolutionHypothesis", "ExperimentPlan", "ExperimentResult",
    "EvaluationResult", "EvolutionVersion", "EvolutionTrace", "EvolutionRecord",
    "EvolutionState", "make_phase6_evaluator",
]
