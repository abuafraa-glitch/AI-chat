"""
Reasoning Engine — محرك الاستدلال
=================================
جزء من HajeenBrainV3 Pipeline الموحّد.

يقوم بـ:
1. تحليل المشكلة وتحديد نوع الاستدلال المطلوب
2. تطبيق استراتيجيات الاستدلال (Chain of Thought, Tree of Thought, إلخ)
3. توليد خطوات تفكير منطقية قبل الوصول للإجابة
4. تقييم جودة الاستدلال
"""

from __future__ import annotations

import asyncio
import json
import logging
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

from pydantic import BaseModel, ConfigDict, Field

# Public compatibility name used by the historical engine contract.
ValidationError = ValueError

logger = logging.getLogger(__name__)


class ReasoningStrategy(Enum):
    """استراتيجيات الاستدلال المتاحة."""
    CHAIN_OF_THOUGHT = "chain_of_thought"      # تفكير خطوة بخطوة
    TREE_OF_THOUGHT = "tree_of_thought"        # شجرة أفكار متعددة
    SELF_CONSISTENCY = "self_consistency"      # اتساق ذاتي
    STEP_BACK = "step_back"                     # التراجع خطوة
    ANALOGICAL = "analogical"                   # استدلال تمثيلي
    CAUSAL = "causal"                           # استدلال سببي
    ABDUCTIVE = "abductive"                     # استدلال استنباطي
    DEDUCTIVE = "deductive"                     # استدلال استقرائي
    DECOMPOSITION = "decomposition"
    FIRST_PRINCIPLES = "first_principles"
    MULTI_PERSPECTIVE = "multi_perspective"
    ANALOGY = "analogy"


class ReasoningStep(BaseModel):
    """خطوة استدلال تدعم العقد الحالية والواجهة التاريخية للاختبارات."""
    model_config = ConfigDict(extra="allow")
    step_number: int
    thought: str = ""
    evidence: Optional[str] = None
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    sub_steps: List["ReasoningStep"] = Field(default_factory=list)
    description: Optional[str] = None
    reasoning: Optional[str] = None
    conclusion: Optional[str] = None
    alternatives: List[str] = Field(default_factory=list)

    def model_post_init(self, __context: Any) -> None:
        if not self.thought:
            self.thought = self.conclusion or self.reasoning or self.description or ""


class SolutionOption(BaseModel):
    title: str
    description: str
    pros: List[str] = Field(default_factory=list)
    cons: List[str] = Field(default_factory=list)
    effort_estimate: str
    risk_level: str
    feasibility_score: float = Field(ge=0.0, le=1.0)


class RiskAssessment(BaseModel):
    risk_type: str
    description: str
    severity: str = Field(pattern=r"^(low|medium|high|critical)$")
    probability: float = Field(ge=0.0, le=1.0)
    impact: str
    mitigation_strategy: str


@dataclass
class ReasoningResult:
    """نتيجة عملية الاستدلال مع خصائص توافق للواجهة القديمة."""
    strategy: ReasoningStrategy
    steps: List[ReasoningStep]
    final_answer: str
    confidence: float
    reasoning_time_ms: float
    metadata: Dict[str, Any] = field(default_factory=dict)

    @property
    def result_id(self) -> str:
        return self.reasoning_id

    def to_dict(self) -> Dict[str, Any]:
        return {
            "result_id": self.result_id,
            "reasoning_id": self.reasoning_id,
            "trace_id": self.trace_id,
            "strategy": self.strategy.value,
            "final_answer": self.final_answer,
            "confidence": self.confidence,
            "reasoning_steps": [step.model_dump() for step in self.steps],
            "solution_options": [option.model_dump() for option in self.solution_options],
            "risks": [risk.model_dump() for risk in self.risks],
            "recommended_solution": self.recommended_solution.model_dump(),
            "reasoning_summary": self.reasoning_summary,
        }

    @property
    def reasoning_id(self) -> str:
        return self.metadata.setdefault("reasoning_id", self.metadata.get("trace_id", "reasoning"))

    @property
    def trace_id(self) -> str:
        return self.metadata.setdefault("trace_id", self.reasoning_id)

    @property
    def reasoning_steps(self) -> List[ReasoningStep]:
        return self.steps

    @property
    def overall_confidence(self) -> float:
        return self.confidence

    @property
    def strategy_used(self) -> ReasoningStrategy:
        return self.strategy

    @property
    def risks(self) -> List[RiskAssessment]:
        return self.metadata.setdefault("risks", [])

    @property
    def solution_options(self) -> List[SolutionOption]:
        return self.metadata.setdefault("solution_options", [SolutionOption(title="الخيار الأساسي", description=self.final_answer, effort_estimate="medium", risk_level="low", feasibility_score=self.confidence)])

    @property
    def recommended_solution(self) -> SolutionOption:
        return self.solution_options[0]

    @property
    def reasoning_summary(self) -> str:
        return self.final_answer


class ReasoningEngine:
    """
    محرك الاستدلال — يحلل المشكلات ويولد خطوات تفكير منطقية.

    يستخدم ضمن HajeenBrainV3 Pipeline:
      Policy → Intent → Context → [Reasoning] → Decision → Execute
    """

    def __init__(self, llm_manager=None, config=None):
        from types import SimpleNamespace
        self.llm_manager = llm_manager
        self.config = config or SimpleNamespace(cache=SimpleNamespace(enabled=True))
        self.trace_manager = SimpleNamespace()
        self.metrics = {"total": 0, "success": 0, "cache_hits": 0}
        self._cache: Dict[str, ReasoningResult] = {}
        self._strategy_weights = {
            ReasoningStrategy.CHAIN_OF_THOUGHT: 0.4,
            ReasoningStrategy.TREE_OF_THOUGHT: 0.2,
            ReasoningStrategy.SELF_CONSISTENCY: 0.15,
            ReasoningStrategy.STEP_BACK: 0.1,
            ReasoningStrategy.ANALOGICAL: 0.05,
            ReasoningStrategy.CAUSAL: 0.05,
            ReasoningStrategy.ABDUCTIVE: 0.03,
            ReasoningStrategy.DEDUCTIVE: 0.02,
        }
        logger.info("ReasoningEngine initialized")

    async def _llm_generate(self, prompt: str, temperature: float = 0.3):
        """استدعاء موحد يدعم واجهتي agenerate وgenerate القديمة."""
        if hasattr(self.llm_manager, "agenerate"):
            return await self.llm_manager.agenerate(prompt, temperature=temperature)
        return await self.llm_manager.generate(prompt, temperature=temperature)

    def get_metrics_summary(self) -> Dict[str, Any]:
        total = self.metrics["total"]
        return {"reasoning": {"total": total, "success_rate": self.metrics["success"] / total if total else 0.0}, "cache": {"hits": self.metrics["cache_hits"]}}

    def get_trace_statistics(self) -> Dict[str, Any]:
        return {"total_traces": self.metrics["total"]}

    def clear_cache(self) -> int:
        count = len(self._cache)
        self._cache.clear()
        return count

    def list_reasoning(self, limit: int = 10) -> List[ReasoningResult]:
        return list(self._cache.values())[:limit]

    # ── Core Methods ──────────────────────────────────────────────────────

    async def reason(
        self,
        problem: str,
        context: Optional[str] = None,
        strategy: Optional[ReasoningStrategy] = None,
        max_steps: int = 5,
        temperature: float = 0.3,
    ) -> ReasoningResult:
        """
        الاستدلال الرئيسي — يحلل المشكلة ويولد خطوات تفكير.

        Args:
            problem: المسألة أو السؤال
            context: سياق إضافي (اختياري)
            strategy: استراتيجية محددة (اختياري — يُختار تلقائياً)
            max_steps: الحد الأقصى لخطوات التفكير
            temperature: درجة الإبداع (0.0 = منطقي صارم, 1.0 = إبداعي)
        """
        import time
        import hashlib
        import uuid
        start = time.perf_counter()
        if not problem or not problem.strip():
            raise ValidationError("problem must not be empty")
        cache_enabled = getattr(getattr(self.config, "cache", None), "enabled", True)
        cache_key = hashlib.sha256(f"{problem}|{context}|{strategy}".encode()).hexdigest()
        if cache_enabled and cache_key in self._cache:
            self.metrics["cache_hits"] += 1
            return self._cache[cache_key]

        # 1. Select strategy if not provided
        if strategy is None:
            strategy = self._select_strategy(problem, context)

        logger.info("Reasoning: strategy=%s, problem_len=%d", strategy.value, len(problem))

        # 2. Generate reasoning steps based on strategy
        if strategy == ReasoningStrategy.CHAIN_OF_THOUGHT:
            steps = await self._chain_of_thought(problem, context, max_steps, temperature)
        elif strategy == ReasoningStrategy.TREE_OF_THOUGHT:
            steps = await self._tree_of_thought(problem, context, max_steps, temperature)
        elif strategy == ReasoningStrategy.SELF_CONSISTENCY:
            steps = await self._self_consistency(problem, context, max_steps, temperature)
        elif strategy == ReasoningStrategy.STEP_BACK:
            steps = await self._step_back(problem, context, max_steps, temperature)
        else:
            steps = await self._chain_of_thought(problem, context, max_steps, temperature)

        # 3. Extract final answer from steps
        final_answer = self._extract_answer(steps)

        # 4. Calculate overall confidence
        confidence = self._calculate_confidence(steps)

        elapsed = (time.perf_counter() - start) * 1000

        result = ReasoningResult(
            strategy=strategy,
            steps=steps,
            final_answer=final_answer,
            confidence=confidence,
            reasoning_time_ms=elapsed,
            metadata={
                "reasoning_id": str(uuid.uuid4()),
                "trace_id": str(uuid.uuid4()),
                "problem_length": len(problem),
                "context_length": len(context) if context else 0,
                "num_steps": len(steps),
            }
        )
        self.metrics["total"] += 1
        self.metrics["success"] += 1
        if cache_enabled:
            self._cache[cache_key] = result
        return result

    # ── Strategy Selection ────────────────────────────────────────────────

    def _select_strategy(
        self,
        problem: str,
        context: Optional[str] = None,
    ) -> ReasoningStrategy:
        """اختيار أفضل استراتيجية بناءً على نوع المشكلة."""
        problem_lower = problem.lower()

        # Problem type detection
        if any(w in problem_lower for w in ["لماذا", "why", "سبب", "cause", "because"]):
            return ReasoningStrategy.CAUSAL

        if any(w in problem_lower for w in ["مقارنة", "compare", "أفضل", "better", "versus", "vs"]):
            return ReasoningStrategy.TREE_OF_THOUGHT

        if any(w in problem_lower for w in ["افترض", "suppose", "if", "لو", "what if"]):
            return ReasoningStrategy.ABDUCTIVE

        if any(w in problem_lower for w in ["جميع", "all", "كل", "every", "always", "never"]):
            return ReasoningStrategy.DEDUCTIVE

        if len(problem) > 200 or (context and len(context) > 500):
            return ReasoningStrategy.CHAIN_OF_THOUGHT

        return ReasoningStrategy.CHAIN_OF_THOUGHT

    # ── Reasoning Strategies ──────────────────────────────────────────────

    async def _chain_of_thought(
        self,
        problem: str,
        context: Optional[str],
        max_steps: int,
        temperature: float,
    ) -> List[ReasoningStep]:
        """تفكير خطوة بخطوة — الأكثر استخداماً."""
        steps = []

        prompt = f"""حلّل المسألة التالية خطوة بخطوة:

المسألة: {problem}

{context or ""}

قدّم خطوات التفكير بالتفصيل ثم الإجابة النهائية."""

        # If LLM available, use it
        if self.llm_manager:
            try:
                response = await self._llm_generate(prompt, temperature=temperature)
                parsed_steps = self._parse_chain_of_thought(response)
                steps.extend(parsed_steps)
            except Exception as exc:
                logger.warning("LLM reasoning failed: %s, using fallback", exc)
                steps = self._fallback_chain_of_thought(problem)
        else:
            steps = self._fallback_chain_of_thought(problem)

        return steps[:max_steps]

    async def _tree_of_thought(
        self,
        problem: str,
        context: Optional[str],
        max_steps: int,
        temperature: float,
    ) -> List[ReasoningStep]:
        """شجرة أفكار — يولد عدة مسارات ويختار الأفضل."""
        # Generate 3 different reasoning paths
        paths = []
        for i in range(3):
            path_prompt = f"""فكّر في المسألة من زاوية مختلفة ({i+1}/3):

المسألة: {problem}

{context or ""}

قدّم مسار تفكير فريد."""

            if self.llm_manager:
                try:
                    response = await self._llm_generate(path_prompt, temperature=temperature + 0.2)
                    path_steps = self._parse_chain_of_thought(response)
                    paths.append(path_steps)
                except:
                    pass

        if not paths:
            return self._fallback_chain_of_thought(problem)

        # Select best path (longest with highest confidence)
        best_path = max(paths, key=lambda p: len(p))
        return best_path[:max_steps]

    async def _self_consistency(
        self,
        problem: str,
        context: Optional[str],
        max_steps: int,
        temperature: float,
    ) -> List[ReasoningStep]:
        """اتساق ذاتي — يولد إجابات متعددة ويختار الأكثر اتساقاً."""
        # Similar to tree of thought but votes on final answer
        answers = []
        for i in range(5):
            if self.llm_manager:
                try:
                    prompt = f"""أجب على المسألة باختصار:

{problem}

{context or ""}

الإجابة النهائية فقط:"""
                    ans = await self._llm_generate(prompt, temperature=0.7)
                    answers.append(ans.strip())
                except:
                    pass

        # Find most common answer
        if answers:
            from collections import Counter
            most_common = Counter(answers).most_common(1)[0][0]

            # Generate reasoning for the most common answer
            prompt = f"""فصّل تفكيرك للوصول لهذه الإجابة:

المسألة: {problem}
الإجابة المتفق عليها: {most_common}

خطوات التفكير:"""

            if self.llm_manager:
                try:
                    response = await self._llm_generate(prompt, temperature=0.3)
                    return self._parse_chain_of_thought(response)[:max_steps]
                except:
                    pass

        return self._fallback_chain_of_thought(problem)

    async def _step_back(
        self,
        problem: str,
        context: Optional[str],
        max_steps: int,
        temperature: float,
    ) -> List[ReasoningStep]:
        """التراجع خطوة — يعيد صياغة المشكلة بشكل أعمق."""
        # First, abstract the problem
        abstract_prompt = f"""أعد صياغة هذه المسألة بشكل أكثر عمومية و abstraction:

المسألة: {problem}

ما المبدأ العام الذي تدور حوله هذه المسألة؟"""

        abstract = problem
        if self.llm_manager:
            try:
                abstract = await self._llm_generate(abstract_prompt, temperature=0.5)
            except:
                pass

        # Then solve the abstracted problem
        solve_prompt = f"""حلّل المسألة العامة ثم طبّق الحل على المسألة الأصلية:

المبدأ العام: {abstract}
المسألة الأصلية: {problem}

{context or ""}

خطوات التفكير:"""

        if self.llm_manager:
            try:
                response = await self._llm_generate(solve_prompt, temperature=temperature)
                return self._parse_chain_of_thought(response)[:max_steps]
            except:
                pass

        return self._fallback_chain_of_thought(problem)

    # ── Helpers ───────────────────────────────────────────────────────────

    def _parse_chain_of_thought(self, text: str) -> List[ReasoningStep]:
        """تحليل نص التفكير إلى خطوات منظمة."""
        steps = []
        lines = text.split("\n")
        current_step = 1
        current_thought = []

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Detect step markers (1., 2., Step 1, etc.)
            if re.match(r"^(\d+[.):]|Step\s+\d+|خطوة\s+\d+)", line, re.IGNORECASE):
                if current_thought:
                    steps.append(ReasoningStep(
                        step_number=current_step,
                        thought="\n".join(current_thought),
                        confidence=0.7,
                    ))
                    current_step += 1
                    current_thought = []
                # Remove step marker from line
                line = re.sub(r"^(\d+[.):]|Step\s+\d+|خطوة\s+\d+)\s*", "", line, flags=re.IGNORECASE)

            current_thought.append(line)

        # Add last step
        if current_thought:
            steps.append(ReasoningStep(
                step_number=current_step,
                thought="\n".join(current_thought),
                confidence=0.7,
            ))

        return steps if steps else self._fallback_chain_of_thought(text)

    def _fallback_chain_of_thought(self, problem: str) -> List[ReasoningStep]:
        """Fallback عند فشل LLM."""
        return [
            ReasoningStep(
                step_number=1,
                thought=f"فهم المسألة: {problem[:100]}...",
                confidence=0.5,
            ),
            ReasoningStep(
                step_number=2,
                thought="تحليل المكونات الرئيسية للمسألة",
                confidence=0.5,
            ),
            ReasoningStep(
                step_number=3,
                thought="تطبيق المنطق والمعرفة المتاحة",
                confidence=0.5,
            ),
        ]

    def _extract_answer(self, steps: List[ReasoningStep]) -> str:
        """استخراج الإجابة النهائية من الخطوات."""
        if not steps:
            return ""
        # Last step usually contains the answer
        last_step = steps[-1]
        return last_step.thought[:500]

    def _calculate_confidence(self, steps: List[ReasoningStep]) -> float:
        """حساب الثقة الإجمالية."""
        if not steps:
            return 0.0
        avg = sum(s.confidence for s in steps) / len(steps)
        # Boost confidence if many steps
        boost = min(len(steps) * 0.05, 0.2)
        return min(avg + boost, 1.0)


# ── Singleton ─────────────────────────────────────────────────────────────

_reasoning_engine: Optional[ReasoningEngine] = None


def get_reasoning_engine(llm_manager=None) -> ReasoningEngine:
    """الحصول على محرك الاستدلال — Singleton."""
    global _reasoning_engine
    if _reasoning_engine is None:
        _reasoning_engine = ReasoningEngine(llm_manager=llm_manager)
    return _reasoning_engine


# Compatibility factory for the historical reasoning-engine contract.
_REASONING_ENGINE_SINGLETON: Optional[ReasoningEngine] = None


def get_reasoning_engine(llm_manager=None, config=None) -> ReasoningEngine:
    global _REASONING_ENGINE_SINGLETON
    if _REASONING_ENGINE_SINGLETON is None:
        _REASONING_ENGINE_SINGLETON = ReasoningEngine(llm_manager=llm_manager, config=config)
    return _REASONING_ENGINE_SINGLETON


def create_reasoning_engine(llm_manager=None, config=None) -> ReasoningEngine:
    return ReasoningEngine(llm_manager=llm_manager, config=config)


def reset_reasoning_engine() -> None:
    global _REASONING_ENGINE_SINGLETON
    _REASONING_ENGINE_SINGLETON = None


ReasoningStep.model_rebuild()
