"""Phase 2 runtime probes.

These probes are test-only. They do not load Qwen weights and do not alter
production startup. The deterministic provider is explicitly injected into an
isolated ModelRouter to prove the platform contract.
"""
from __future__ import annotations

import importlib

import pytest

from brain.brain_v3 import BrainRequest, HajeenBrainV3
from brain.model_router import ModelRouter
from tests.integration.test_phase2_runtime_contract import VerifiedProvider


@pytest.mark.parametrize(
    "module_name",
    [
        "api.v1.ai.router",
        "brain.brain_v3",
        "brain.model_router",
        "core.model.model_registry",
        "core.llm.providers.hajeen_provider",
    ],
)
def test_phase2_canonical_modules_import_without_runtime_model_load(module_name):
    module = importlib.import_module(module_name)
    assert module is not None


@pytest.mark.asyncio
async def test_phase2_runtime_trace_api_brain_router_provider():
    router = ModelRouter(prefer_local=False)
    router.register_provider("hajeen-local", VerifiedProvider(text="phase2 probe"))
    brain = HajeenBrainV3()
    brain.model_router = router

    response = await brain.process(
        BrainRequest(
            request_id="phase2-probe",
            session_id="phase2-probe-session",
            user_message="probe",
            context={"use_rag": False},
            max_tokens=32,
        )
    )

    assert response.content == "phase2 probe"
    assert response.trace.provider == "local"
    assert response.trace.execution["prompt_builder"] == "UnifiedPromptBuilder"
    assert router._routing_history
    assert router._routing_history[-1]["model"] == "hajeen-local"


@pytest.mark.asyncio
async def test_phase2_unverified_local_route_fails_closed_without_fallback():
    router = ModelRouter(prefer_local=True)
    result = await router.route(
        messages=[{"role": "user", "content": "probe"}],
        capability="general",
        budget_tokens=32,
        prefer_local=True,
    )
    assert result.success is False
    assert result.response == ""
    assert result.metadata.get("fail_closed") is True
    assert result.provider == "none"
