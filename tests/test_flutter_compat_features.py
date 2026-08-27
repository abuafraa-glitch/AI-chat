from api.v1.compat_router import _title_from_message, router


def test_first_message_title_is_meaningful_and_bounded():
    title = _title_from_message("  اشرح لي طبقات هاجين الداخلية بالتفصيل  ", [])
    assert title.startswith("اشرح لي")
    assert len(title) <= 61


def test_attachment_only_title_uses_file_name():
    assert _title_from_message("", [{"name": "photo.png"}]) == "مرفق: photo.png"


def test_mobile_feature_routes_exist_without_404_contract_gaps():
    routes = {(route.path, tuple(sorted(route.methods or []))) for route in router.routes}
    paths = {path for path, _ in routes}
    assert "/notifications" in paths
    assert "/files" in paths
    assert "/agents" in paths
    assert "/subscriptions/plans" in paths
    assert "/subscriptions/current" in paths
    assert "/payments/history" in paths
    assert "/subscriptions/{subscription_id}/cancel" in paths


import base64
import json
from starlette.requests import Request
from api.v1.compat_router import _groq_model, _scope


def test_mobile_model_ids_are_always_namespaced_to_groq():
    assert _groq_model("llama-3.3-70b-versatile") == "groq/llama-3.3-70b-versatile"
    assert _groq_model("openai/gpt-oss-20b") == "groq/gpt-oss-20b"
    assert _groq_model("groq/llama-3.3-70b-versatile") == "groq/llama-3.3-70b-versatile"


def test_jwt_scope_uses_stable_account_identity_not_raw_token():
    def token(email: str) -> str:
        payload = base64.urlsafe_b64encode(
            json.dumps({"sub": email}).encode()
        ).decode().rstrip("=")
        return f"header.{payload}.signature"

    first = Request({"type": "http", "headers": [(b"authorization", f"Bearer {token('A@example.com')}".encode())]})
    rotated = Request({"type": "http", "headers": [(b"authorization", f"Bearer {token('a@example.com')}".encode())]})
    assert _scope(first) == _scope(rotated) == "account:a@example.com"
