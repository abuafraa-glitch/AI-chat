"""pytest configuration and shared fixtures for all test suites."""

from __future__ import annotations

import asyncio
import os
from pathlib import Path
import pytest

# API integration fixtures are functional tests, not authentication tests.
# Production keeps ENABLE_AUTH=true by default; tests opt out explicitly.
os.environ.setdefault("ENABLE_AUTH", "false")


@pytest.fixture
def brain_mock():
    """Legacy fixture name backed by the real Brain runtime only.

    Load tests must never substitute a production mock.  When no verified
    local checkpoint is configured, the test is skipped explicitly and the
    closure report records REAL_HAJEEN_MODEL as unavailable.
    """
    checkpoint = os.getenv("HAJEEN_LOCAL_MODEL_PATH") or os.getenv("REAL_HAJEEN_MODEL_PATH")
    if not checkpoint or not Path(checkpoint).exists():
        pytest.skip("REAL_HAJEEN_MODEL unavailable: no verified local checkpoint")
    from brain.brain_v3 import HajeenBrainV3
    return HajeenBrainV3()


def pytest_configure(config):
    """إعداد pytest markers."""
    config.addinivalue_line("markers", "asyncio: mark test as async")


@pytest.fixture(scope="session")
def event_loop_policy():
    """Use the default asyncio event loop policy."""
    return asyncio.DefaultEventLoopPolicy()


@pytest.fixture(scope="session")
def event_loop():
    """Create a single shared event loop for the test session."""
    policy = asyncio.DefaultEventLoopPolicy()
    loop = policy.new_event_loop()
    asyncio.set_event_loop(loop)
    yield loop
    loop.close()
