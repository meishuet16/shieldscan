from types import SimpleNamespace

from app.models.scan import ScanResult, ThreatIntelMatch, ThreatLevel
from app.services import gemini_service


def _base_result() -> ScanResult:
    return ScanResult(
        threat_level=ThreatLevel.HIGH,
        confidence_score=78,
        summary_en="Initial semantic summary",
        summary_bm="Ringkasan semantik awal",
        indicators=[],
        recommendation_en="Verify independently",
        recommendation_bm="Sahkan secara bebas",
        rag_matches=[],
        scan_duration_ms=10,
        ai_confidence_score=61,
        deterministic_score=70,
        risk_evidence=[],
        scoring_version="shieldscan-v2.1",
    )


def _match() -> ThreatIntelMatch:
    return ThreatIntelMatch(
        id="BNM-PHISHING-GUIDANCE",
        title="Phishing guidance",
        category="phishing",
        source_name="Bank Negara Malaysia — Financial Fraud Alerts",
        source_url="https://www.bnm.gov.my/financial-fraud-alerts",
        matched_terms=["login"],
        summary="Lookalike websites may steal banking credentials.",
        retrieval_method="local-keyword-v1",
    )


def test_grounded_synthesis_updates_narrative_but_not_risk(monkeypatch):
    fake_response = SimpleNamespace(
        text='''{
          "summary_en": "Grounded English summary",
          "summary_bm": "Ringkasan BM berasaskan bukti",
          "recommendation_en": "Use the official bank channel",
          "recommendation_bm": "Gunakan saluran rasmi bank",
          "threat_level": "SAFE",
          "confidence_score": 1
        }'''
    )

    def fake_generate_content(*, model, contents):
        assert "AUTHORITATIVE RISK" in contents
        assert "BNM-PHISHING-GUIDANCE" in contents
        return fake_response

    monkeypatch.setattr(gemini_service.client.models, "generate_content", fake_generate_content)

    result = _base_result()
    grounded = gemini_service.synthesize_grounded_report(result, [_match()])

    assert grounded.summary_en == "Grounded English summary"
    assert grounded.recommendation_en == "Use the official bank channel"
    assert grounded.threat_level == ThreatLevel.HIGH
    assert grounded.confidence_score == 78
    assert grounded.ai_confidence_score == 61
    assert grounded.deterministic_score == 70


def test_grounded_synthesis_is_noop_without_matches(monkeypatch):
    def should_not_run(**kwargs):
        raise AssertionError("Gemini should not run when retrieval returned no evidence")

    monkeypatch.setattr(gemini_service.client.models, "generate_content", should_not_run)
    result = _base_result()

    grounded = gemini_service.synthesize_grounded_report(result, [])

    assert grounded is result
    assert grounded.summary_en == "Initial semantic summary"
