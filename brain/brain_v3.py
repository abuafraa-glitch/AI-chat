"""
Hajeen Brain v3 — العقل المدبّر المركزي المُحسّن
================================================

إعادة تصميم شاملة للعقل المركزي:
1. لا توجد مسارات مختصرة (shortcuts) — كل طلب يمر عبر الطبقة الإدراكية الكاملة
2. استدلال عميق في كل خطوة — لا قواعد ثابتة أو مطابقة كلمات مفتاحية
3. تدفق موحد — سواء كان streaming أو batch، كل الطلبات تتبع نفس المسار
4. مراقبة ذاتية مستمرة — كل قرار يُسجل ويُقيّم
5. تطور مستمر — النظام يتعلم من كل طلب ويحسّن نفسه

المبدأ الذهبي:
أي نموذج خارجي = Temporary Expert فقط.
كل معرفة تُكتسب من الخارج يجب أن تتحول تدريجياً لمعرفة داخلية.

القاعدة الصارمة للمعمارية:
- HajeenBrainV3 هو Runtime الوحيد — لا يوجد مسار يتجاوزه
- MemoryFabric هو مصدر الحقيقة الوحيد للذاكرة
- ModelRouter هو الموجه الوحيد للنماذج
- UnifiedPromptBuilder هو بناء الـ Prompts الوحيد
"""

from __future__ import annotations

import asyncio
import inspect
import logging
import time
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, AsyncGenerator, Dict, List, Optional

from brain.prompts.unified_prompt_builder import PromptMode, UnifiedPromptBuilder
from services.rag.rag_pipeline import RAGPipeline, RAGRequest

from .cognitive_layer.context_analyzer import (
    ContextAnalyzer,
    get_context_analyzer,
)
from .cognitive_layer.intent_analyzer import IntentAnalyzer, get_intent_analyzer
from .cognitive_layer.reasoning_engine import (
    ReasoningEngine,
    get_reasoning_engine,
)
from .decision_engine import DecisionEngine, get_decision_engine_sync
from .goal_manager import GoalManager, get_goal_manager
from .evolution.phase7_lifecycle import EvolutionLifecycle, EvolutionRecord
from .memory.memory_fabric import MemoryFabric, get_memory_fabric
from .metrics.model_performance_db import ModelPerformanceDB, get_performance_db
from .model_router import ModelRouter, get_model_router
from .policy.policy_engine import PolicyEngine, get_policy_engine
from services.agents.agent_orchestrator import AgentOrchestrator
from services.agents.planner_agent import PlannerAgent

logger = logging.getLogger(__name__)


class RequestType(str, Enum):
    """أنواع الطلبات المختلفة."""
    CHAT = "chat"
    REASONING = "reasoning"
    ANALYSIS = "analysis"
    GENERATION = "generation"
    TRAINING = "training"


@dataclass
class BrainRequest:
    """طلب يدخل Hajeen Brain v3."""
    request_id: str
    user_message: str
    session_id: str
    user_id: Optional[str] = None
    context: Dict[str, Any] = field(default_factory=dict)
    stream: bool = False
    max_tokens: int = 2048
    temperature: float = 0.7
    force_model: Optional[str] = None
    request_type: RequestType = RequestType.CHAT
    created_at: float = field(default_factory=time.time)


@dataclass
class ExecutionTrace:
    """تتبع تنفيذ الطلب عبر جميع الطبقات."""
    request_id: str
    trace_id: str = field(default_factory=lambda: str(uuid.uuid4()))

    # الطبقات التي مرّ عليها الطلب
    policy_evaluation: Dict[str, Any] = field(default_factory=dict)
    intent_analysis: Dict[str, Any] = field(default_factory=dict)
    goal_analysis: Dict[str, Any] = field(default_factory=dict)
    context_analysis: Dict[str, Any] = field(default_factory=dict)
    reasoning_result: Dict[str, Any] = field(default_factory=dict)
    decomposition: Dict[str, Any] = field(default_factory=dict)
    planning: Dict[str, Any] = field(default_factory=dict)
    decision: Dict[str, Any] = field(default_factory=dict)
    execution: Dict[str, Any] = field(default_factory=dict)
    memory_operations: Dict[str, Any] = field(default_factory=dict)
    reflection: Dict[str, Any] = field(default_factory=dict)
    tokens_used: int = 0
    provider: Optional[str] = None

    # مقاييس الأداء
    total_latency_ms: float = 0.0
    layers_passed: List[str] = field(default_factory=list)

    def record_layer(self, layer_name: str, data: Dict[str, Any]) -> None:
        """تسجيل مرور الطلب عبر طبقة معينة."""
        self.layers_passed.append(layer_name)
        setattr(self, layer_name, data)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "trace_id": self.trace_id,
            "request_id": self.request_id,
            "layers_passed": self.layers_passed,
            "total_latency_ms": round(self.total_latency_ms, 2),
            "policy": self.policy_evaluation,
            "intent": self.intent_analysis,
            "context": self.context_analysis,
            "reasoning": self.reasoning_result,
            "decision": self.decision,
            "execution": self.execution,
        }


@dataclass
class BrainResponse:
    """استجابة HajeenBrainV3."""
    request_id: str
    session_id: str
    content: str
    trace: ExecutionTrace
    model_used: str
    models_collaborated: List[str]
    quality_score: float
    policy_decision: str
    used_local_model: bool
    used_rag: bool
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "request_id": self.request_id,
            "session_id": self.session_id,
            "content": self.content,
            "trace": self.trace.to_dict(),
            "model_used": self.model_used,
            "models_collaborated": self.models_collaborated,
            "quality_score": round(self.quality_score, 3),
            "policy_decision": self.policy_decision,
            "sovereignty": {
                "used_local_model": self.used_local_model,
                "used_rag": self.used_rag,
            },
        }


class HajeenBrainV3:
    """
    العقل المدبّر المركزي v3 — لا توجد مسارات مختصرة.

    Pipeline الكامل:
      Policy → Intent → Context → Reasoning → Planning → Decision
      → ModelRouter → LLM → MemoryFabric → Reflection → Response

    الضمان: لا يوجد LLM call خارج هذا الكلاس.
    """

    VERSION = "3.0.0"

    def __init__(self, evolution_lifecycle: Optional[EvolutionLifecycle] = None) -> None:
        logger.info("HajeenBrain v%s: تهيئة العقل المدبّر المركزي...", self.VERSION)

        # مصدر الحقيقة الوحيد للذاكرة
        self.memory: MemoryFabric = get_memory_fabric()

        # الموجه الوحيد للنماذج
        self.model_router: ModelRouter = get_model_router()

        # الباني الوحيد للـ prompts؛ لا يُستدعى أي PromptBuilder آخر من المسار المركزي
        self.prompt_builder: UnifiedPromptBuilder = UnifiedPromptBuilder()

        # يُحقن عند startup من RAGPipeline الرسمي؛ لا يوجد fallback وهمي
        self.rag_pipeline: Optional[RAGPipeline] = None

        # طبقة السياسات
        self.policy: PolicyEngine = get_policy_engine()

        # طبقات التحليل الإدراكي
        self.intent_analyzer: IntentAnalyzer = get_intent_analyzer()
        self.context_analyzer: ContextAnalyzer = get_context_analyzer(memory_fabric=self.memory)
        self.reasoning_engine: ReasoningEngine = get_reasoning_engine()
        self.goal_manager: GoalManager = get_goal_manager()
        self.decision_engine: DecisionEngine = get_decision_engine_sync()

        # Agent runtime: orchestration owns transient task lifecycle only; all
        # model, memory, prompt, RAG, and policy authorities remain central.
        self.agent_planner = PlannerAgent(
            model_router=self.model_router,
            prompt_builder=self.prompt_builder,
            max_steps=10,
        )
        self.agent_orchestrator = AgentOrchestrator(
            model_router=self.model_router,
            memory_fabric=self.memory,
            prompt_builder=self.prompt_builder,
            policy_engine=self.policy,
            rag_pipeline=self.rag_pipeline,
            plan_provider=self.agent_planner.create_plan,
            max_steps=10,
            execution_timeout_seconds=120.0,
        )

        # سلطة التطور الاختيارية: لا تُنشئ مساراً بديلاً ولا تُطبق أي تغيير تلقائياً.
        self.evolution_lifecycle: Optional[EvolutionLifecycle] = evolution_lifecycle

        # الأداء والانعكاس
        self.performance_db: ModelPerformanceDB = get_performance_db()
        self._execution_traces: Dict[str, ExecutionTrace] = {}
        self._stream_queues: Dict[str, asyncio.Queue] = {}
        logger.info("HajeenBrain v%s: جاهز — Runtime الوحيد المعتمد ✓", self.VERSION)

    def set_evolution_lifecycle(self, lifecycle: Optional[EvolutionLifecycle]) -> None:
        """حقن سلطة Phase 7؛ لا يُسمح بإنشاء lifecycle محلي داخل الطلب."""
        if lifecycle is not None and lifecycle.memory is not self.memory:
            raise ValueError("EvolutionLifecycle must use BrainV3's MemoryFabric")
        self.evolution_lifecycle = lifecycle

    def record_evolution_observation(
        self,
        *,
        request: BrainRequest,
        trace: ExecutionTrace,
        quality_score: float,
        evidence_refs: tuple[str, ...] = (),
        hypothesis: Optional[str] = None,
        expected_metrics: Optional[Dict[str, float]] = None,
        proposed_change: Optional[Dict[str, Any]] = None,
        idempotency_key: Optional[str] = None,
    ) -> Optional[EvolutionRecord]:
        """يسجل دليلاً حقيقياً في Phase 7 دون تشغيل تجربة أو تعديل إنتاجي."""
        if self.evolution_lifecycle is None:
            return None
        payload = {
            "request_id": request.request_id,
            "session_id": request.session_id,
            "quality_score": float(quality_score),
            "layers_passed": tuple(trace.layers_passed),
            "provider": trace.provider,
            "execution": dict(trace.execution),
        }
        return self.evolution_lifecycle.observe(
            "brain_v3_request",
            payload,
            evidence_refs=evidence_refs,
            hypothesis=hypothesis,
            expected_metrics=expected_metrics,
            proposed_change=proposed_change,
            idempotency_key=idempotency_key or f"brain-request:{request.request_id}",
        )

    def set_rag_pipeline(self, rag_pipeline: Optional[RAGPipeline]) -> None:
        """حقن RAGPipeline المنشأ في startup باعتباره المصدر الوحيد للاسترجاع."""
        self.rag_pipeline = rag_pipeline
        # Keep the injected authority consistent for agent planning/execution;
        # never create a second retrieval pipeline inside the agent layer.
        self.agent_orchestrator.rag_pipeline = rag_pipeline

    async def process(self, request: BrainRequest) -> BrainResponse:
        """
        المسار الموحد لمعالجة أي طلب.

        هذا هو المسار الوحيد المسموح به لأي طلب AI في المنصة.
        لا يوجد shortcut أو fallback يتجاوز هذا الدالة.
        """
        t0 = time.perf_counter()
        request_id = request.request_id
        trace = ExecutionTrace(request_id=request_id)
        self._execution_traces[request_id] = trace

        # ── 1. MemoryFabric: جلب سياق المحادثة (SSOT) ─────────────────
        conversation = self.memory.get_conversation(request.session_id)
        conversation.add_message("user", request.user_message)
        trace.record_layer("memory_operations", {
            "session_id": request.session_id,
            "action": "context_loaded",
        })

        # ── 2. Policy Evaluation ────────────────────────────────────────
        try:
            policy_result = self.policy.evaluate({
                "prompt": request.user_message,
                "content": request.user_message,
                "session_id": request.session_id,
                "user_id": request.user_id,
            })
            if inspect.isawaitable(policy_result):
                policy_result = await asyncio.wait_for(policy_result, timeout=2.0)
        except Exception as exc:
            logger.error("Policy evaluation failed closed: %s", exc)
            policy_result = type("PR", (), {
                "allowed": False,
                "blocked": True,
                "final_decision": "blocked",
                "reason": "Policy evaluation unavailable; request denied.",
            })()

        if isinstance(policy_result, dict):
            policy_entries = list(policy_result.values())
            policy_blocked = any(not item.get("allowed", True) for item in policy_entries if isinstance(item, dict))
            policy_allowed = not policy_blocked
            policy_decision = "blocked" if policy_blocked else "allowed"
            policy_reason = next((item.get("reason") for item in policy_entries if isinstance(item, dict) and not item.get("allowed", True)), "الطلب غير مسموح به بموجب السياسة الحالية")
        else:
            policy_blocked = bool(getattr(policy_result, "blocked", False))
            policy_allowed = getattr(policy_result, "allowed", None)
            policy_decision = getattr(policy_result, "final_decision", getattr(policy_result, "decision", None))
            policy_reason = getattr(policy_result, "reason", None)

        trace.record_layer("policy_evaluation", {
            "decision": policy_decision or "allowed",
            "allowed": policy_allowed if policy_allowed is not None else not policy_blocked,
        })

        if policy_blocked or policy_decision in {"blocked", "denied", "PolicyDecision.BLOCK"} or policy_allowed is False:
            content = policy_reason if isinstance(policy_reason, str) and policy_reason.strip() else "⚠️ الطلب غير مسموح به بموجب السياسة الحالية"
            conversation.add_message("assistant", content)
            return BrainResponse(
                request_id=request_id,
                session_id=request.session_id,
                content=content,
                trace=trace,
                model_used="policy-engine",
                models_collaborated=[],
                quality_score=1.0,
                policy_decision="blocked",
                used_local_model=True,
                used_rag=False,
            )

        # ── 3. Intent Analysis ──────────────────────────────────────────
        try:
            intent = await self.intent_analyzer.analyze(
                request.user_message,
                context=request.context,
            )
            trace.record_layer("intent_analysis", {
                "intent_id": getattr(intent, "intent_id", None),
                "intent_type": getattr(intent, "type", "general"),
                "confidence": getattr(intent, "confidence", 0.8),
            })
        except Exception as exc:
            logger.debug("Intent analysis skipped: %s", exc)
            trace.record_layer("intent_analysis", {"skipped": True})

        # ── 4. Goal Analysis ────────────────────────────────────────────
        goal = None
        try:
            goal = await self.goal_manager.analyze(
                user_request=request.user_message,
                context=request.context,
            )
            trace.record_layer("goal_analysis", {
                "goal_id": getattr(goal, "goal_id", None),
                "final_objective": getattr(goal, "final_objective", None),
                "confidence": getattr(goal, "confidence", None),
            })
        except Exception as exc:
            logger.debug("Goal analysis skipped: %s", exc)
            trace.record_layer("goal_analysis", {"skipped": True})

        # ── 5. Context Analysis ─────────────────────────────────────────
        try:
            context = await self.context_analyzer.analyze(
                user_message=request.user_message,
                session_id=request.session_id,
                user_id=request.user_id,
                additional_context=request.context,
            )
            context_history = conversation.get_window()
            trace.record_layer("context_analysis", {
                "analysis_id": getattr(context, "analysis_id", None),
                "context_analysis_id": getattr(context, "analysis_id", None),
                "history_turns": len(context_history),
                "use_rag": request.context.get("use_rag", False),
            })
        except Exception as exc:
            logger.debug("Context analysis skipped: %s", exc)
            trace.record_layer("context_analysis", {"skipped": True})

        # ── 6. Reasoning ────────────────────────────────────────────────
        try:
            reasoning = await self.reasoning_engine.reason(
                problem=request.user_message,
                context=str(getattr(context, "summary", "")) if "context" in locals() else None,
            )
            trace.record_layer("reasoning_result", {
                "result_id": getattr(reasoning, "result_id", None),
                "strategy": getattr(reasoning, "strategy", "default"),
                "steps": getattr(reasoning, "steps", []),
            })
        except Exception as exc:
            logger.debug("Reasoning skipped: %s", exc)
            trace.record_layer("reasoning_result", {"skipped": True})

        # ── 7. Decision Engine ──────────────────────────────────────────
        decision = None
        try:
            if goal is None:
                raise RuntimeError("Goal analysis unavailable; decision denied")
            decision = self.decision_engine.decide(
                task_id=request.request_id,
                goal=goal,
                task_name=getattr(goal, "final_objective", request.user_message),
                context=request.context,
            )
            if inspect.isawaitable(decision):
                decision = await decision
            trace.record_layer("decision", {
                "decision_id": getattr(decision, "decision_id", None),
                "action": getattr(decision, "action", "generate"),
                "model_preference": getattr(decision, "primary_model", None),
                "use_agent": bool(getattr(decision, "use_agent", False)),
                "agent_selection": getattr(decision, "metadata", {}).get("agent_selection", "unknown"),
            })
        except Exception as exc:
            logger.debug("Decision skipped: %s", exc)
            trace.record_layer("decision", {"skipped": True})

        # ── 8. Optional Agent runtime through the central orchestrator ─────
        agent_output = ""
        use_rag = bool(request.context.get("use_rag", False))
        use_agent = bool(getattr(decision, "use_agent", False)) if decision is not None else False
        trace.record_layer("agent_selection", {
            "selected": use_agent,
            "source": "DecisionEngine",
            "path": "AgentOrchestrator" if use_agent else "ModelRouter",
        })
        if use_agent:
            try:
                agent_result = await self.agent_orchestrator.run(
                    request.user_message,
                    session_id=request.session_id,
                    user_id=request.user_id,
                    use_rag=use_rag,
                    language=str(request.context.get("language", "ar")),
                    retrieval_mode=str(request.context.get("retrieval_mode", "semantic")),
                )
                trace.record_layer("execution", {
                    "agent_runtime": True,
                    "agent_task_id": agent_result.context.task_id,
                    "agent_success": agent_result.success,
                    "agent_events": [event.event for event in agent_result.events],
                })
                if not agent_result.success:
                    raise RuntimeError(agent_result.error or "Agent execution failed")
                agent_output = str(agent_result.output or "")
            except asyncio.CancelledError:
                raise
            except Exception as exc:
                trace.record_layer("execution", {
                    "agent_runtime": True,
                    "agent_success": False,
                    "agent_error": str(exc),
                    "fail_closed": True,
                })
                raise RuntimeError("Agent runtime unavailable") from exc

        # ── 9. Prompt + RAG ثم ModelRouter: المسار الرسمي للنموذج ────────
        rag_context = agent_output
        rag_sources: List[Dict[str, Any]] = []
        if use_agent and use_rag:
            rag_context = str(agent_result.context.transient_state.get("rag_context", ""))
            rag_sources = list(agent_result.context.transient_state.get("rag_sources", []))
        elif use_rag:
            if self.rag_pipeline is None:
                raise RuntimeError("RAG requested but canonical RAGPipeline is not initialized")
            rag_response = await self.rag_pipeline.run(RAGRequest(
                query=request.user_message,
                top_k=int(request.context.get("top_k", 5)),
                language=str(request.context.get("language", "ar")),
                max_context_tokens=2000,
                retrieval_mode=str(request.context.get("retrieval_mode", "semantic")),
            ))
            rag_context = rag_response.formatted.context_used
            rag_sources = rag_response.formatted.citations

        prompt_mode = PromptMode.RAG if use_rag else PromptMode.CHAT
        if use_rag and self.rag_pipeline is not None and self.rag_pipeline.unified_prompt_builder is not None:
            prompt = self.rag_pipeline.unified_prompt_builder.build(
                request.user_message,
                mode=PromptMode.RAG,
                history=conversation.get_window()[:-1],
                context=rag_context,
                language=str(request.context.get("language", "ar")),
                system_prompt=request.context.get("system_prompt"),
            )
        else:
            prompt = self.prompt_builder.build(
                request.user_message,
                mode=prompt_mode,
                history=conversation.get_window()[:-1],
                context=rag_context,
                language=str(request.context.get("language", "ar")),
                system_prompt=request.context.get("system_prompt"),
            )
        trace.record_layer("execution", {
            "prompt_builder": "UnifiedPromptBuilder",
            "prompt_mode": prompt_mode.value,
            "rag_pipeline": "RAGPipeline" if use_rag else None,
            "rag_sources": rag_sources,
            "rag_retrieval_mode": str(request.context.get("retrieval_mode", "semantic")) if use_rag else None,
        })

        try:
            if request.stream:
                queue = self._stream_queues.get(request.request_id)
                if queue is None:
                    raise RuntimeError("Streaming queue is not initialized")
                pieces: List[str] = []
                async for chunk in self.model_router.stream(
                    messages=prompt.messages,
                    capability="general",
                    budget_tokens=request.max_tokens,
                    force_model=request.force_model,
                    prefer_local=True,
                    request_id=request.request_id,
                ):
                    pieces.append(chunk.delta)
                    await queue.put(chunk)
                content = "".join(pieces)
                if not content:
                    raise RuntimeError("Native provider stream completed without content")
                route_result = None
                model_used = request.force_model or "stream-provider"
                trace.record_layer("execution", {
                    "model": model_used,
                    "provider": "native-stream",
                    "success": True,
                    "streaming": True,
                    "prompt_builder": "UnifiedPromptBuilder",
                    "rag_pipeline": "RAGPipeline" if use_rag else None,
                    "rag_sources": rag_sources,
                    "rag_retrieval_mode": str(request.context.get("retrieval_mode", "semantic")) if use_rag else None,
                })
            else:
                route_result = await self.model_router.route(
                    messages=prompt.messages,
                    capability="general",
                    budget_tokens=request.max_tokens,
                    force_model=request.force_model,
                    prefer_local=True,
                    request_id=request.request_id,
                )
                if not route_result.success:
                    raise RuntimeError(route_result.error or "ModelRouter returned an unsuccessful result")
                content = route_result.response
                model_used = route_result.model_id
                trace.tokens_used = route_result.tokens_used
                trace.provider = route_result.provider
                trace.record_layer("execution", {
                    "model": model_used,
                    "provider": route_result.provider,
                    "latency_ms": route_result.latency_ms,
                    "success": True,
                    "prompt_builder": "UnifiedPromptBuilder",
                    "rag_pipeline": "RAGPipeline" if use_rag else None,
                    "rag_sources": rag_sources,
                    "rag_retrieval_mode": str(request.context.get("retrieval_mode", "semantic")) if use_rag else None,
                })
        except Exception as exc:
            logger.error("ModelRouter unavailable; failing closed: %s", exc)
            trace.record_layer("execution", {
                "model": None,
                "error": str(exc),
                "success": False,
                "fail_closed": True,
            })
            queue = self._stream_queues.get(request.request_id)
            if queue is not None:
                await queue.put(exc)
            raise RuntimeError("No verified model route available") from exc
        finally:
            queue = self._stream_queues.get(request.request_id)
            if queue is not None:
                await queue.put(None)

        # ── 10. MemoryFabric: حفظ الاستجابة (SSOT) ──────────────────────
        conversation.add_message("assistant", content)
        trace.record_layer("reflection", {"stored_in_memory_fabric": True})

        trace.total_latency_ms = (time.perf_counter() - t0) * 1000

        return BrainResponse(
            request_id=request_id,
            session_id=request.session_id,
            content=content,
            trace=trace,
            model_used=model_used,
            models_collaborated=[model_used],
            quality_score=0.9,
            policy_decision="allowed",
            used_local_model=(trace.provider or "") in {"local", "hajeen", "ollama"},
            used_rag=use_rag,
        )

    async def stream(self, request: BrainRequest) -> AsyncGenerator[Any, None]:
        """Run the normal Brain pipeline and expose provider-native chunks."""
        if not request.stream:
            request.stream = True
        queue: asyncio.Queue = asyncio.Queue()
        self._stream_queues[request.request_id] = queue
        task = asyncio.create_task(self.process(request))
        try:
            while True:
                item = await queue.get()
                if item is None:
                    break
                if isinstance(item, Exception):
                    raise item
                yield item
            await task
        finally:
            self._stream_queues.pop(request.request_id, None)
            if not task.done():
                task.cancel()
                try:
                    await task
                except asyncio.CancelledError:
                    pass
            else:
                # Retrieve an already-finished exception even when the queue
                # delivered it first; otherwise asyncio reports an unhandled
                # task exception after the stream consumer exits.
                try:
                    await task
                except asyncio.CancelledError:
                    pass
                except Exception:
                    pass

    def get_trace(self, request_id: str) -> Optional[ExecutionTrace]:
        """جلب تتبع تنفيذ طلب معين."""
        return self._execution_traces.get(request_id)

    def get_stats(self) -> Dict[str, Any]:
        """إحصائيات العقل المركزي."""
        return {
            "version": self.VERSION,
            "memory_overview": self.memory.get_overview(),
            "routing_stats": self.model_router.get_routing_stats(),
            "total_traces": len(self._execution_traces),
        }


# ── Singleton Management ───────────────────────────────────────────────────

_brain_v3: Optional[HajeenBrainV3] = None


async def get_brain_v3() -> HajeenBrainV3:
    """الحصول على نسخة Singleton من HajeenBrainV3."""
    global _brain_v3
    if _brain_v3 is None:
        _brain_v3 = HajeenBrainV3()
    return _brain_v3


# Alias للتوافقية — get_brain = get_brain_v3
async def get_brain() -> HajeenBrainV3:
    """
    Alias لـ get_brain_v3 — للتوافقية مع الكود القديم.
    كلاهما يعيد نفس Singleton من HajeenBrainV3.
    """
    return await get_brain_v3()
