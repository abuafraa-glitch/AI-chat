from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] in {"ok", "degraded"}
    assert payload.get("service") == "Hajeen AI Platform"

def test_ping():
    response = client.get("/ping")
    assert response.status_code == 200
    payload = response.json()
    assert payload["message"] == "pong"
    assert isinstance(payload.get("timestamp"), (int, float))
