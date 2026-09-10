from datetime import datetime, timezone

from app.models.scan import ScanResult, ThreatLevel
from app.services.network_intelligence import (
    NetworkIntelSignal,
    _parse_rdap_created_at,
    analyze_network_url,
)
from app.services.network_safety import ResolvedAddress
from app.services.risk_engine import apply_network_intelligence


def _result(score: int = 30) -> ScanResult:
    return ScanResult(
        threat_level=ThreatLevel.LOW,
        confidence_score=score,
        summary_en="test",
        summary_bm="test",
        indicators=[],
        recommendation_en="test",
        recommendation_bm="test",
        rag_matches=[],
        scan_duration_ms=1,
        deterministic_score=10,
        risk_evidence=[],
    )


def test_parse_rdap_registration_event():
    created = _parse_rdap_created_at(
        {
            "events": [
                {"eventAction": "last changed", "eventDate": "2026-08-10T00:00:00Z"},
                {"eventAction": "registration", "eventDate": "2026-01-02T03:04:05Z"},
            ]
        }
    )

    assert created == datetime(2026, 1, 2, 3, 4, 5, tzinfo=timezone.utc)


def test_non_public_dns_target_is_blocked_before_tls_or_rdap(monkeypatch):
    monkeypatch.setattr(
        "app.services.network_intelligence.resolve_public_addresses",
        lambda host: [
            ResolvedAddress(host=host, ip="127.0.0.1", is_public=False, reason="blocked")
        ],
    )

    signals = analyze_network_url("https://example.test/login")

    assert [signal.code for signal in signals] == ["non_public_destination"]
    assert signals[0].weight == 30


def test_network_risk_contribution_is_capped_at_25_points():
    result = _result(30)
    signals = [
        NetworkIntelSignal("young_domain", "Young domain", 20, "10 days old"),
        NetworkIntelSignal("tls_unverified", "TLS failed", 8, "failed"),
        NetworkIntelSignal("dns_public", "Public DNS", 0, "203.0.113.8"),
    ]

    updated = apply_network_intelligence(result, signals)

    assert updated.deterministic_score == 35
    assert updated.confidence_score == 55
    assert updated.threat_level == ThreatLevel.MEDIUM
    assert len(updated.risk_evidence) == 3


def test_positive_network_metadata_never_reduces_risk_score():
    result = _result(45)
    updated = apply_network_intelligence(
        result,
        [NetworkIntelSignal("tls_valid", "TLS validated", 0, "valid")],
    )

    assert updated.confidence_score == 45
    assert updated.deterministic_score == 10
