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


@pytest.fixture(autouse=True)
def isolate_test_runtime(request, monkeypatch):
    """Prevent cross-test auth and FastAPI app-state leakage.

    Integration tests may temporarily enable authentication or attach runtime
    services to the global app.  Restore the test-safe baseline after every
    test without weakening production middleware.
    """
    previous_auth = os.environ.get("ENABLE_AUTH")
    # The channel workflow contract intentionally runs without auth, while
    # phase5 boundary tests intentionally exercise auth=true.
    if request.path.name == "test_api_workflow.py":
        monkeypatch.setenv("ENABLE_AUTH", "false")
    app = None
    previous_state = None
    try:
        from api.main import app as imported_app
        app = imported_app
        previous_state = dict(vars(app.state))
    except Exception:
        pass
    yield
    if app is not None and previous_state is not None:
        for key in list(vars(app.state)):
            if key not in previous_state:
                try:
                    delattr(app.state, key)
                except AttributeError:
                    pass
        for key, value in previous_state.items():
            setattr(app.state, key, value)
    if previous_auth is None:
        os.environ.pop("ENABLE_AUTH", None)
    else:
        os.environ["ENABLE_AUTH"] = previous_auth


@pytest.fixture(autouse=True)
def ensure_default_event_loop():
    """Keep legacy synchronous tests compatible with Python 3.12 loop lifecycle."""
    try:
        asyncio.get_event_loop()
    except RuntimeError:
        asyncio.set_event_loop(asyncio.new_event_loop())
    yield


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
