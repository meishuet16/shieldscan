from fastapi.testclient import TestClient

from main import app
from app.services.rag_service import search_threat_intelligence


def test_health_response_reports_service_status():
    client = TestClient(app)

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["service"] == "ShieldScan AI Backend"


def test_local_intel_returns_provenance_when_it_matches():
    matches = search_threat_intelligence(
        "Maybank2u login verification required for your bank account."
    )

    assert matches
    assert matches[0].source_name.startswith("Bank Negara Malaysia")
    assert matches[0].retrieval_method == "local-keyword-v1"
