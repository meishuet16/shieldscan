from app.models.scan import FraudIndicator, ScanResult, ThreatLevel
from app.services.network_intelligence import NetworkIntelSignal
from app.services.risk_engine import apply_network_intelligence, apply_risk_engine
from app.services.url_intelligence import analyze_url, url_signal_score


def _result(ai_score: int) -> ScanResult:
    return ScanResult(
        threat_level=ThreatLevel.MEDIUM,
        confidence_score=ai_score,
        summary_en="test",
        summary_bm="test",
        indicators=[
            FraudIndicator(
                category="phishing",
                description="semantic model indicator",
                severity="medium",
            )
        ],
        recommendation_en="verify",
        recommendation_bm="sahkan",
        scan_duration_ms=1,
    )


def test_non_url_scan_preserves_semantic_risk_score_and_records_ai_score():
    result = apply_risk_engine("text", "ordinary message", _result(62))

    assert result.confidence_score == 62
    assert result.ai_confidence_score == 62
    assert result.deterministic_score == 0
    assert result.risk_evidence == []


def test_url_scan_uses_deterministic_signals_plus_bounded_ai_support():
    url = "https://maybank2u-secure-login.xyz/verify/account"
    deterministic = url_signal_score(analyze_url(url))
    result = apply_risk_engine("url", url, _result(80))

    assert result.ai_confidence_score == 80
    assert result.deterministic_score == deterministic
    assert result.confidence_score == min(100, deterministic + 20)
    assert result.threat_level in {ThreatLevel.HIGH, ThreatLevel.CRITICAL}
    assert {item.code for item in result.risk_evidence} >= {
        "brand_impersonation",
        "suspicious_tld",
        "credential_bait_path",
    }


def test_brand_impersonation_floor_is_at_least_high_when_ai_score_is_zero():
    result = apply_risk_engine(
        "url",
        "https://maybank2u-secure-login.xyz/verify/account",
        _result(0),
    )

    assert result.confidence_score >= 65
    assert result.threat_level in {ThreatLevel.HIGH, ThreatLevel.CRITICAL}


def test_network_points_are_capped_and_zero_weight_context_does_not_lower_score():
    result = apply_risk_engine("url", "https://example.com/", _result(40))
    before = result.confidence_score

    updated = apply_network_intelligence(
        result,
        [
            NetworkIntelSignal("young_domain", "Young domain", 20, "10 days old"),
            NetworkIntelSignal("tls_unverified", "TLS failed", 8, "failed"),
            NetworkIntelSignal("dns_public", "Public DNS", 0, "203.0.113.8"),
        ],
    )

    assert updated.confidence_score == min(100, before + 25)
    assert updated.deterministic_score == 25
    assert next(item for item in updated.risk_evidence if item.code == "dns_public").score == 0
