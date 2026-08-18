"""
Hajeen Model v1 — واجهة النموذج المحلي المعتمد.

يدير هذا الملف الاستدلال المحلي والتحقق من جاهزية artifact وtokenizer وnative streaming. لا توجد فيه نتائج وهمية أو مزودات خارجية مباشرة.
"""
from __future__ import annotations

import asyncio
import logging
import os
import time
import uuid
from dataclasses import dataclass, field
from typing import AsyncGenerator, Dict, List, Optional

import yaml
from dotenv import load_dotenv
from pathlib import Path

load_dotenv()
logger = logging.getLogger(__name__)

# ─── Configuration ────────────────────────────────────────────────────────────

_CONFIG_PATH = Path(__file__).parent / "config" / "model_config.yaml"

LOCAL_ONLY_MODE: bool = True
DISABLED_PROVIDERS: List[str] = ["ollama", "qwen", "openai", "cohere"]


def _load_config() -> Dict:
    try:
        with open(_CONFIG_PATH, encoding="utf-8") as f:
            return yaml.safe_load(f)
    except Exception:
        return {}


CONFIG = _load_config()
_INF = CONFIG.get("inference", {})

MODEL_NAME = CONFIG.get("model", {}).get("name", "Hajeen Foundation Model v1")
SYSTEM_PROMPT = CONFIG.get("system_prompt", "أنت مساعد ذكي اسمك حاجين.")

# مسارات الأوزان المحلية
LOCAL_MODEL_WEIGHTS = os.getenv("MODEL_WEIGHTS_DIR", "./model_weights")
LOCAL_TOKENIZER_PATH = os.getenv("TOKENIZER_OUTPUT_DIR", "./tokenizer_output")

logger.info("Hajeen local-only runtime enabled; external providers are disabled")

# ─── Data Classes ─────────────────────────────────────────────────────────────


@dataclass
class HajeenMessage:
    role: str  # system | user | assistant
    content: str

    def to_dict(self) -> Dict:
        return {"role": self.role, "content": self.content}


@dataclass
class HajeenRequest:
    messages: List[HajeenMessage]
    temperature: float = 0.7
    max_tokens: int = 1024
    stream: bool = False
    session_id: Optional[str] = None
    request_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])


@dataclass
class HajeenResponse:
    content: str
    model: str
    provider: str
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    latency_ms: float = 0.0
    finish_reason: str = "stop"
    request_id: Optional[str] = None
    is_mock: bool = False
    is_local: bool = False

    def to_dict(self) -> Dict:
        return {
            "content": self.content,
            "model": self.model,
            "provider": self.provider,
            "is_mock": self.is_mock,
            "is_local": self.is_local,
            "usage": {
                "prompt_tokens": self.prompt_tokens,
                "completion_tokens": self.completion_tokens,
                "total_tokens": self.total_tokens,
            },
            "latency_ms": round(self.latency_ms, 2),
            "finish_reason": self.finish_reason,
            "request_id": self.request_id,
        }


# ─── Local Model Provider (PRIMARY) ──────────────────────────────────────────

_local_inference_engine = None


def _get_local_engine():
    """الحصول على محرك الاستدلال المحلي (lazy init)."""
    global _local_inference_engine
    if _local_inference_engine is None:
        try:
            from hajeen_model.core.local_inference_engine import (
                LocalInferenceEngine, LocalInferenceConfig,
            )
            config = LocalInferenceConfig(
                model_path=LOCAL_MODEL_WEIGHTS,
                tokenizer_path=LOCAL_TOKENIZER_PATH,
                device="auto",
            )
            _local_inference_engine = LocalInferenceEngine(config=config)
            if LOCAL_ONLY_MODE:
                _local_inference_engine.load_model()
        except Exception as e:
            logger.warning(f"⚠️  لم يتم تحميل Local Engine: {e}")
            _local_inference_engine = None
    return _local_inference_engine


def _is_local_model_available() -> bool:
    """التحقق الصارم من توفر artifact وtokenizer معاً."""
    weights_dir = Path(LOCAL_MODEL_WEIGHTS)
    tokenizer_dir = Path(LOCAL_TOKENIZER_PATH)
    has_weights = any(weights_dir.glob("**/*.pt")) if weights_dir.exists() else False
    has_tokenizer = (tokenizer_dir / "tokenizer.json").is_file() if tokenizer_dir.is_dir() else tokenizer_dir.is_file()
    return has_weights and has_tokenizer


async def _local_complete(request: "HajeenRequest") -> "HajeenResponse":
    """استدلال عبر النموذج المحلي فقط."""
    engine = _get_local_engine()
    if engine is None:
        raise RuntimeError("Local inference engine غير متاح")

    user_text = ""
    for m in reversed(request.messages):
        if m.role == "user":
            user_text = m.content
            break

    loop = asyncio.get_event_loop()
    local_resp = await loop.run_in_executor(
        None,
        lambda: engine.generate(
            prompt=f"{SYSTEM_PROMPT}\n\nالمستخدم: {user_text}\nحاجين:",
            max_new_tokens=request.max_tokens,
            temperature=request.temperature,
        ),
    )

    return HajeenResponse(
        content=local_resp.content,
        model="HajeenFoundationModel",
        provider="local_weights",
        prompt_tokens=local_resp.prompt_tokens,
        completion_tokens=local_resp.completion_tokens,
        total_tokens=local_resp.total_tokens,
        latency_ms=local_resp.latency_ms,
        finish_reason=local_resp.finish_reason,
        request_id=request.request_id,
        is_mock=False,
        is_local=True,
    )


# ─── Mock Provider ────────────────────────────────────────────────────────────

# External providers are intentionally absent from this local runtime.  Provider
# selection belongs to the central ModelRouter, not this model facade.

# ─── Public API ───────────────────────────────────────────────────────────────


class HajeenModelV1:
    """
    الواجهة الرئيسية لـ Hajeen Foundation Model v1.

    المسار الوحيد: local_weights مع artifact وtokenizer معتمدين. عند غيابهما يفشل runtime صراحة.

    الاستخدام:
        model = HajeenModelV1()
        response = await model.chat("ما هو الذكاء الاصطناعي؟")
        print(response.content)
    """

    def __init__(self):
        self._local_available: Optional[bool] = None
        self._stats = {
            "total_requests": 0,
            "local_requests": 0,
            "errors": 0,
        }
        logger.info("Hajeen local-only runtime initialized")

    def _check_local_available(self) -> bool:
        if self._local_available is None:
            self._local_available = _is_local_model_available()
        return self._local_available

    async def chat(
        self,
        user_message: str,
        history: Optional[List[Dict]] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> HajeenResponse:
        """دردشة مع النموذج."""
        messages = []
        for h in (history or []):
            messages.append(HajeenMessage(h.get("role", "user"), h.get("content", "")))
        messages.append(HajeenMessage("user", user_message))
        request = HajeenRequest(messages=messages, temperature=temperature, max_tokens=max_tokens)
        return await self.complete(request)

    async def complete(self, request: HajeenRequest) -> HajeenResponse:
        """استدلال محلي fail-closed عبر artifact معتمد فقط."""
        self._stats["total_requests"] += 1
        if not self._check_local_available():
            self._stats["errors"] += 1
            raise RuntimeError("MODEL_NOT_READY: approved local artifact and tokenizer are unavailable")
        try:
            resp = await _local_complete(request)
            self._stats["local_requests"] += 1
            return resp
        except asyncio.CancelledError:
            self._stats["errors"] += 1
            raise
        except Exception:
            self._stats["errors"] += 1
            raise

    async def stream(
        self, user_message: str, history: Optional[List[Dict]] = None
    ) -> AsyncGenerator[str, None]:
        """Provider-native local streaming only; no synthetic fallback."""
        if not self._check_local_available():
            raise RuntimeError("MODEL_NOT_READY: approved local artifact and tokenizer are unavailable")
        engine = _get_local_engine()
        if engine is None:
            raise RuntimeError("MODEL_NOT_READY: local inference engine is unavailable")
        prompt = f"{SYSTEM_PROMPT}\n\nالمستخدم: {user_message}\nحاجين:"
        async for token in engine.stream_generate(prompt):
            yield token

    async def health(self) -> Dict:
        """فحص حالة النموذج والمزودين."""
        local_avail = _is_local_model_available()
        self._local_available = local_avail
        active = "local_weights" if local_avail else "none"

        return {
            "model": MODEL_NAME,
            "version": "1.0.0",
            "architecture": "HajeenFoundationModel",
            "local_only_mode": True,
            "disabled_providers": list(DISABLED_PROVIDERS),
            "local_weights_available": local_avail,
            "local_weights_path": LOCAL_MODEL_WEIGHTS,
            "active_provider": active,
            "hf_model_repo": "Raedthawaba/hajeen-model",
            "hf_dataset_repo": "Raedthawaba/hajeen-datasets",
            "stats": self._stats,
            "status": "ready" if local_avail else "not_ready",
            "readiness": bool(local_avail),
        }

    def reset_cache(self):
        """إعادة فحص المزودين عند الاستدعاء القادم."""
        self._local_available = None

    def reset_ollama_cache(self):
        """للتوافق مع الإصدارات السابقة."""
        self.reset_cache()


# ─── Singleton ───────────────────────────────────────────────────────────────

_instance: Optional[HajeenModelV1] = None


def get_hajeen_model() -> HajeenModelV1:
    global _instance
    if _instance is None:
        _instance = HajeenModelV1()
    return _instance
