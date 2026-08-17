# Brain and Authority Audit
Mon Aug 17 19:11:04 UTC 2026

## class HajeenBrainV3
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/brain_v3.py:181:class HajeenBrainV3:
## class MemoryFabric
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/memory/memory_fabric.py:281:class MemoryFabric:
## class ModelRouter
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/model_router.py:108:class ModelRouter:
## class UnifiedPromptBuilder
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/prompts/unified_prompt_builder.py:49:class UnifiedPromptBuilder(AbstractPromptBuilder):
## class GoalManager
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/goal_manager.py:112:class GoalManager:
## class TaskDecomposer
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/task_decomposer.py:107:class TaskDecomposer:
## class GraphPlanner
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/graph_planner.py:132:class GraphPlanner:
## class DecisionEngine
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/cognitive_layer/decision_engine.py:82:class DecisionEngine:
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/decision_engine.py:66:class DecisionEngine:
## class InferenceEngine
/home/ubuntu/backend_Ai_review/hajeen_platform/core/inference_engine/engine.py:23:class InferenceEngine:
/home/ubuntu/backend_Ai_review/hajeen_platform/hajeen_model/hybrid_models/inference/inference_engine.py:91:class InferenceEngine:
/home/ubuntu/backend_Ai_review/hajeen_platform/hajeen_model/inference/inference_engine.py:6:class InferenceEngine:

## Direct provider/fake response indicators
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/learning/continuous_learning.py:419:                    "status": "deferred_local_checkpoint_required",
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/learning/continuous_learning.py:422:                "simulated": False,
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/learning/continuous_learning.py:526:                "simulated": False,
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/learning/continuous_learning.py:551:                "simulated": False,
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/model_router.py:199:            success=False,
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/decision_engine.py:282:                    "provider": "unknown", # Provider needs to be inferred or passed
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/metrics/model_performance_db.py:102:    def _get_or_create(self, model_id: str, provider: str = "unknown") -> ModelMetrics:
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/metrics/model_performance_db.py:246:                    provider=md.get("provider", "unknown"),
/home/ubuntu/backend_Ai_review/hajeen_platform/hajeen_model/inference/hajeen_provider.py:49:            # Even if loading fails, we return a simulated response as requested for the mock phase
/home/ubuntu/backend_Ai_review/hajeen_platform/core/distributed/kubernetes_runtime.py:156:                "K8s client not connected — manifest generated for '%s':\n%s",
/home/ubuntu/backend_Ai_review/hajeen_platform/core/distributed/kubernetes_runtime.py:178:            logger.warning("K8s client not connected — cannot scale '%s'.", name)

## Prompt builders
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/prompts/unified_prompt_builder.py
/home/ubuntu/backend_Ai_review/hajeen_platform/core/prompts/prompt_builder.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/prompts/prompt_builder.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/rag/prompt_builder.py

## Memory authority candidates
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/cognitive_layer/experience_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/brain/memory/memory_fabric.py
/home/ubuntu/backend_Ai_review/hajeen_platform/core/context_intelligence/semantic_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/core/memory/long_term_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/core/memory/memory_manager.py
/home/ubuntu/backend_Ai_review/hajeen_platform/core/memory/short_term_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/agents/memory_agent.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/agents/multi_agent/shared_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/memory/conversation_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/memory/summarization_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/memory/vector_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/services/memory_service.py
/home/ubuntu/backend_Ai_review/hajeen_platform/tests/self_evolution/test_episodic_memory.py
/home/ubuntu/backend_Ai_review/hajeen_platform/tests/unit/test_memory_unification_runtime.py
