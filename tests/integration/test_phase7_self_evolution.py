import asyncio

import pytest

from brain.evolution.phase7_lifecycle import EvolutionLifecycle, EvolutionState


class Memory:
    def __init__(self):
        self.episodes = []
        self.semantic = []

    def record_episode(self, event_type, description, outcome):
        self.episodes.append((event_type, description, outcome))

    def memorize_semantically(self, content, metadata=None):
        self.semantic.append((content, metadata or {}))
        return content


def test_observation_requires_explicit_hypothesis_and_is_idempotent():
    memory = Memory()
    lifecycle = EvolutionLifecycle(memory=memory)
    with pytest.raises(Exception):
        lifecycle.observe("runtime", {"score": 0.2})
    first = lifecycle.observe("runtime", {"score": 0.2}, hypothesis="improve retrieval", idempotency_key="k")
    second = lifecycle.observe("runtime", {"score": 0.2}, hypothesis="different", idempotency_key="k")
    assert first.experiment_id == second.experiment_id
    assert first.state is EvolutionState.HYPOTHESIS

@pytest.mark.asyncio
async def test_no_executor_is_fail_closed_without_result():
    lifecycle = EvolutionLifecycle(memory=Memory())
    record = lifecycle.observe("runtime", {"x": 1}, hypothesis="test")
    result = await lifecycle.run_experiment(record.experiment_id)
    assert result.state is EvolutionState.FAILED
    assert result.result is None

@pytest.mark.asyncio
async def test_full_evidence_gated_lifecycle_and_rollback():
    memory = Memory()
    deployed = []
    rolled_back = []

    async def executor(hypothesis, cancel):
        assert hypothesis.statement == "improve retrieval"
        return {"metrics": {"quality": 0.91}, "observations": {"n": 4}, "evidence_refs": ("run-1",), "executor_id": "real-test"}

    async def reflector(record):
        assert record.result is not None
        return {"strengths": ["evidence"]}

    async def evaluator(record):
        return {"metrics": {"quality": 0.91}, "passes_threshold": True, "benchmark_ref": "bench-1"}

    async def policy(action, context):
        return action == "approve_evolution" and context["candidate_ref"] == "candidate-1"

    async def deployer(record):
        deployed.append(record.candidate_ref)
        return "deployment-1"

    async def rollbacker(ref):
        rolled_back.append(ref)

    lifecycle = EvolutionLifecycle(memory=memory, executor=executor, reflector=reflector,
        evaluator=evaluator, policy=policy, deployer=deployer, rollbacker=rollbacker)
    record = lifecycle.observe("runtime", {"score": 0.2}, hypothesis="improve retrieval", evidence_refs=("obs-1",))
    await lifecycle.run_experiment(record.experiment_id)
    await lifecycle.reflect_and_evaluate(record.experiment_id)
    await lifecycle.approve(record.experiment_id, candidate_ref="candidate-1")
    await lifecycle.deploy(record.experiment_id)
    result = await lifecycle.rollback(record.experiment_id)
    assert result.state is EvolutionState.ROLLED_BACK
    assert deployed == ["candidate-1"]
    assert rolled_back == ["deployment-1"]
    assert any(x[0] == "self_evolution" for x in memory.episodes)
    assert {item.event for item in result.trace} >= {"experiment_completed", "evaluation_completed", "approval_granted", "deployment_completed", "rollback_completed"}

@pytest.mark.asyncio
async def test_cancellation_does_not_create_result():
    memory = Memory()
    started = asyncio.Event()

    async def executor(hypothesis, cancel):
        started.set()
        while not cancel.is_set():
            await asyncio.sleep(0.01)
        raise asyncio.CancelledError

    lifecycle = EvolutionLifecycle(memory=memory, executor=executor, timeout_seconds=0.5)
    record = lifecycle.observe("runtime", {"x": 1}, hypothesis="cancel me")
    task = asyncio.create_task(lifecycle.run_experiment(record.experiment_id))
    await started.wait()
    lifecycle.cancel(record.experiment_id)
    with pytest.raises(asyncio.CancelledError):
        await task
    assert lifecycle.get(record.experiment_id).state is EvolutionState.CANCELLED
    assert lifecycle.get(record.experiment_id).result is None

@pytest.mark.asyncio
async def test_missing_reflection_or_policy_fails_closed():
    lifecycle = EvolutionLifecycle(memory=Memory(), executor=lambda h, c: {"metrics": {"x": 1}})
    record = lifecycle.observe("runtime", {"x": 1}, hypothesis="test")
    await lifecycle.run_experiment(record.experiment_id)
    result = await lifecycle.reflect_and_evaluate(record.experiment_id)
    assert result.state is EvolutionState.FAILED
    assert result.error == "reflector_and_evaluator_required"


def test_unsafe_capability_is_rejected_before_experiment():
    lifecycle = EvolutionLifecycle(memory=Memory())
    with pytest.raises(Exception, match="unsafe experiment capability"):
        lifecycle.observe(
            "runtime",
            {"x": 1, "secrets": "not allowed"},
            hypothesis="unsafe change",
        )


@pytest.mark.asyncio
async def test_missing_metric_fails_closed():
    async def executor(hypothesis, cancel):
        return {"metrics": {"quality": 0.9}}

    async def reflector(record):
        return {"evidence": True}

    async def evaluator(record):
        return {"metrics": {"quality": 0.9}, "passes_threshold": True}

    lifecycle = EvolutionLifecycle(
        memory=Memory(), executor=executor, reflector=reflector, evaluator=evaluator
    )
    record = lifecycle.observe(
        "runtime", {"x": 1}, hypothesis="measure latency", expected_metrics={"latency": 0.2}
    )
    await lifecycle.run_experiment(record.experiment_id)
    result = await lifecycle.reflect_and_evaluate(record.experiment_id)
    assert result.state is EvolutionState.FAILED
    assert result.error == "missing_metrics:latency"


@pytest.mark.asyncio
async def test_deployment_requires_approval_and_is_idempotent():
    calls = []

    async def deployer(record):
        calls.append(record.experiment_id)
        return "deployment-once"

    lifecycle = EvolutionLifecycle(memory=Memory(), deployer=deployer)
    record = lifecycle.observe("runtime", {"x": 1}, hypothesis="candidate")
    blocked = await lifecycle.deploy(record.experiment_id, idempotency_key="deploy-1")
    assert blocked.state is EvolutionState.FAILED
    assert calls == []


@pytest.mark.asyncio
async def test_policy_denial_is_rejected_without_version_or_deployment():
    async def executor(hypothesis, cancel):
        return {"metrics": {"quality": 0.9}}

    async def reflector(record):
        return {"evidence": True}

    async def evaluator(record):
        return {"metrics": {"quality": 0.9}, "passes_threshold": True}

    async def policy(action, context):
        return False

    lifecycle = EvolutionLifecycle(
        memory=Memory(), executor=executor, reflector=reflector,
        evaluator=evaluator, policy=policy, deployer=lambda record: "never"
    )
    record = lifecycle.observe("runtime", {"x": 1}, hypothesis="candidate")
    await lifecycle.run_experiment(record.experiment_id)
    await lifecycle.reflect_and_evaluate(record.experiment_id)
    result = await lifecycle.approve(record.experiment_id, candidate_ref="candidate-1")
    assert result.state is EvolutionState.REJECTED
    assert result.version is None
    assert result.approval is not None
    assert result.approval.status == "REJECTED"


@pytest.mark.asyncio
async def test_legacy_learning_pipeline_never_deploys_without_canonical_gate(tmp_path):
    from brain.learning.continuous_learning import ContinuousLearningPipeline

    pipeline = ContinuousLearningPipeline(storage_path=str(tmp_path))
    raw = [
        {
            "instruction": f"اشرح مفهوم الذكاء الاصطناعي رقم {i}",
            "output": f"الذكاء الاصطناعي رقم {i} هو مجال حاسوبي يدرس بناء الأنظمة الذكية بالتفصيل.",
            "quality_score": 0.9,
        }
        for i in range(60)
    ]
    run = await pipeline.run(raw)
    assert run.deployment_info == {}
    assert not (tmp_path / "model_registry.json").exists()
    assert not (tmp_path / "active_model.json").exists()
