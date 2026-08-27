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
