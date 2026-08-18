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
