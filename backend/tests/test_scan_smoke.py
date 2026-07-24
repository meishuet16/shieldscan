from fastapi.testclient import TestClient

from main import app
from app.services.rag_service import search_rag_database


def test_health_response_reports_service_status():
    client = TestClient(app)

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["service"] == "ShieldScan AI Backend"


def test_local_rag_matches_malaysian_prize_scam_keywords():
    matches = search_rag_database(
        "Tahniah, anda menang RM5000. Klik untuk tuntut hadiah.",
        "HIGH",
    )

    assert matches
    assert "WhatsApp Prize Scam" in matches[0]
