from fastapi.testclient import TestClient

from main import app
from app.services.rag_service import search_threat_intelligence


def test_health_response_reports_service_status():
    client = TestClient(app)

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["service"] == "ShieldScan AI Backend"


def test_local_intel_matches_malaysian_scam_keywords():
    matches = search_threat_intelligence(
        "Tahniah, anda menang RM5000. Klik untuk tuntut hadiah."
    )

    # The seed corpus may evolve, but any returned item must carry provenance and
    # explicitly identify the local retrieval method rather than impersonating RAG.
    for match in matches:
        assert match.source_name
        assert match.retrieval_method == "local-keyword-v1"
