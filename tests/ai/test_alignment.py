import json
import os

import pytest

from core.alignment.alignment_pipeline import AlignmentPipeline
from core.alignment.evaluation_system import AlignmentEvaluator
from core.alignment.preference_dataset import PreferenceDatasetBuilder
from core.alignment.reward_model import RewardModelPipeline
from services.alignment.dpo_pipeline import DPOPipeline
from services.alignment.rlhf_infrastructure import RLHFInfrastructure


class MockModel:
    """Test-only model double for alignment orchestration contracts."""

    def __call__(self, *args, **kwargs):
        return 0.5


class MockPolicyModel(MockModel):
    pass


class MockRewardModel(MockModel):
    pass


class MockTokenizer:
    """Test-only tokenizer double with the minimal alignment interface."""

    def encode(self, text, return_tensors=None):
        return [1, 2, 3]

    def __call__(self, text, return_tensors=None):
        return {"input_ids": self.encode(text, return_tensors=return_tensors)}


def test_preference_dataset_builder(tmp_path):
    output_dir = tmp_path / "alignment"
    builder = PreferenceDatasetBuilder(output_path=str(output_dir))
    
    builder.add_example("Hello", "Hi there!", "Go away")
    saved_path = builder.save("test_prefs.jsonl")
    
    assert os.path.exists(saved_path)
    with open(saved_path, 'r') as f:
        data = json.loads(f.readline())
        assert data["prompt"] == "Hello"
        assert data["chosen"] == "Hi there!"
        assert data["rejected"] == "Go away"

def test_reward_model_pipeline():
    # Test with dummy scoring
    pipeline = RewardModelPipeline()
    score = pipeline.score_response("Test prompt", "Test response")
    assert score.score == 0.5
    
    ranking = pipeline.rank_responses("Prompt", ["Bad", "Good"])
    assert len(ranking) == 2
    assert ranking[0]["score"] == 0.5

def test_alignment_evaluator():
    evaluator = AlignmentEvaluator()
    results = evaluator.run_full_eval("Hello", "I am a helpful assistant")
    
    assert "safety" in results
    assert "quality" in results
    assert "overall_alignment_score" in results
    assert results["quality"]["helpfulness_score"] == 0.85

def test_alignment_pipeline(tmp_path):
    output_dir = tmp_path / "alignment_pipe"
    pipeline = AlignmentPipeline()
    pipeline.dataset_builder.output_path = output_dir
    
    raw_data = [
        {"prompt": "Q1", "chosen": "A1", "rejected": "B1"},
        {"prompt": "Q2", "chosen": "A2", "rejected": "B2"}
    ]
    
    path = pipeline.build_preference_dataset(raw_data, "pipe_test.jsonl")
    assert os.path.exists(path)

@pytest.mark.asyncio
async def test_dpo_pipeline_init():
    model = MockModel()
    ref_model = MockModel()
    tokenizer = MockTokenizer()
    pipeline = DPOPipeline(model, ref_model, tokenizer)
    assert pipeline is not None

@pytest.mark.asyncio
async def test_dpo_prepare_preference_data():
    model = MockModel()
    ref_model = MockModel()
    tokenizer = MockTokenizer()
    pipeline = DPOPipeline(model, ref_model, tokenizer)
    
    preferences = [
        {"prompt": "P1", "chosen_response": "C1", "rejected_response": "R1"},
        {"prompt": "P2", "chosen_response": "C2", "rejected_response": "R2"},
    ]
    processed_data = pipeline.prepare_preference_data(preferences)
    assert len(processed_data) == 2
    assert processed_data[0] == ("P1", "C1", "R1")

@pytest.mark.asyncio
async def test_dpo_run_pipeline(monkeypatch):
    pipeline = DPOPipeline(MockModel(), MockModel(), MockTokenizer())
    pipeline.setup_trainer = lambda train_dataset, eval_dataset=None: None
    pipeline.train = lambda: {"status": "completed", "metrics": {"loss": 0.1}}
    preferences = [
        {"prompt": "P1", "chosen_response": "C1", "rejected_response": "R1"},
    ]
    results = await pipeline.run_pipeline(preferences, epochs=1)
    assert results["status"] == "completed"
    assert results["metrics"]["loss"] > 0

@pytest.mark.asyncio
async def test_rlhf_infrastructure_init():
    policy_model = MockPolicyModel()
    reward_model = MockRewardModel()
    tokenizer = MockTokenizer()
    infra = RLHFInfrastructure(policy_model, reward_model, tokenizer)
    assert infra is not None

@pytest.mark.asyncio
async def test_rlhf_collect_human_feedback():
    policy_model = MockPolicyModel()
    reward_model = MockRewardModel()
    tokenizer = MockTokenizer()
    infra = RLHFInfrastructure(policy_model, reward_model, tokenizer)
    
    prompts = ["Prompt A", "Prompt B"]
    feedback = await infra.collect_human_feedback(prompts)
    assert len(feedback) == 2
    assert "chosen_response" in feedback[0]

@pytest.mark.asyncio
async def test_rlhf_train_reward_model():
    infra = RLHFInfrastructure(MockPolicyModel(), MockRewardModel(), MockTokenizer())

    class Trainer:
        def train(self):
            return type("TrainResult", (), {"metrics": {"loss": 0.2}})()

    infra._reward_trainer = Trainer()
    results = infra.train_reward_model()
    assert results["loss"] > 0

@pytest.mark.asyncio
async def test_rlhf_run_pipeline(monkeypatch):
    infra = RLHFInfrastructure(MockPolicyModel(), MockRewardModel(), MockTokenizer())
    async def generate_fn(prompt):
        return "test response"
    infra.setup_reward_model_trainer = lambda train_dataset, eval_dataset=None: None
    infra.train_reward_model = lambda: {"loss": 0.2}
    infra.setup_ppo_trainer = lambda dataset=None: None
    async def run_ppo_step(prompt, generated_response):
        return {"success": True, "ppo_loss": 0.3}
    infra.run_ppo_step = run_ppo_step
    results = await infra.run_rlhf_pipeline(
        ["Prompt X"], reward_model_epochs=1, ppo_steps=1, generate_fn=generate_fn
    )
    assert results["status"] == "completed"
    assert results["average_ppo_loss"] > 0
