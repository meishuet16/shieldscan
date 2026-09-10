from app.models.scan import ScanResult, ThreatIntelMatch, ThreatLevel
from app.services.risk_engine import apply_risk_engine


def _match() -> ThreatIntelMatch:
    return ThreatIntelMatch(
        id="BNM-TEST",
        title="Test intelligence",
        category="phishing",
        source_name="Bank Negara Malaysia",
        source_url="https://www.bnm.gov.my/example",
        matched_terms=["login"],
        summary="Test record",
        retrieval_method="local-keyword-v3",
        retrieval_score=0.5,
        published_at="2026-08-03",
        agency="BNM",
    )


def _result(score: int = 55) -> ScanResult:
    return ScanResult(
        threat_level=ThreatLevel.MEDIUM,
        confidence_score=score,
        summary_en="test",
        summary_bm="test",
        indicators=[],
        recommendation_en="verify",
        recommendation_bm="sahkan",
        rag_matches=[_match()],
        scan_duration_ms=1,
    )


def test_legacy_fields_populate_explicit_response_names():
    result = _result(55)
    payload = result.model_dump(mode="json")

    assert payload["risk_score"] == payload["confidence_score"] == 55
    assert payload["threat_intel_matches"] == payload["rag_matches"]
    assert payload["threat_intel_matches"][0]["published_at"] == "2026-08-03"
    assert payload["threat_intel_matches"][0]["agency"] == "BNM"


def test_risk_engine_keeps_new_and_legacy_score_fields_in_sync():
    result = apply_risk_engine(
        "url",
        "https://maybank2u-secure-login.xyz/verify/account",
        _result(80),
    )

    assert result.risk_score == result.confidence_score


def test_primary_threat_intel_field_populates_legacy_alias():
    result = ScanResult(
        threat_level=ThreatLevel.LOW,
        risk_score=25,
        confidence_score=25,
        summary_en="test",
        summary_bm="test",
        indicators=[],
        recommendation_en="verify",
        recommendation_bm="sahkan",
        threat_intel_matches=[_match()],
        scan_duration_ms=1,
    )

    assert result.threat_intel_matches == result.rag_matches
