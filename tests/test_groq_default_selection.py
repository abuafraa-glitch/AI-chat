import asyncio

from brain.decision_engine import DecisionEngine
from brain.goal_manager import ComplexityLevel, Goal, IntentType


def make_goal(domain: str) -> Goal:
    return Goal(
        goal_id="test-goal",
        original_request="اختبار اختيار النموذج",
        final_objective="اختبار المسار الافتراضي",
        intent=IntentType.CONVERSATION,
        complexity=ComplexityLevel.SIMPLE,
        domain=domain,
        sub_tasks=[],
        required_tools=[],
        suitable_models=[],
        confidence=1.0,
    )


def test_auto_selection_uses_groq_for_supported_domains():
    engine = DecisionEngine()
    for domain in ("general", "arabic", "code", "math", "rag"):
        decision = asyncio.run(
            engine.decide(
                task_id=f"test-{domain}",
                goal=make_goal(domain),
                task_name="اختبار المسار التلقائي",
            )
        )
        assert decision.primary_model == "groq/openai/gpt-oss-20b"
        assert not decision.primary_model.startswith("ollama/")
        assert decision.fallback_model is None


def test_training_branch_remains_explicitly_internal():
    assert DecisionEngine.MODEL_RULES["training"]["primary"] == "local_pipeline"
