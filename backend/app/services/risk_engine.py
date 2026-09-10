from typing import Iterable, List

from app.models.scan import RiskEvidence, ScanResult, ThreatLevel
from app.services.network_intelligence import NetworkIntelSignal
from app.services.url_intelligence import UrlSignal, analyze_url, url_signal_score


SCORING_VERSION = "shieldscan-v2.2"


def score_to_level(score: int) -> ThreatLevel:
    if score >= 85:
        return ThreatLevel.CRITICAL
    if score >= 65:
        return ThreatLevel.HIGH
    if score >= 40:
        return ThreatLevel.MEDIUM
    if score >= 20:
        return ThreatLevel.LOW
    return ThreatLevel.SAFE


def _url_evidence(signals: Iterable[UrlSignal]) -> List[RiskEvidence]:
    return [
        RiskEvidence(
            source="url_intelligence",
            code=signal.code,
            label=signal.label,
            score=signal.weight,
            evidence=signal.evidence,
        )
        for signal in signals
    ]


def _network_evidence(signals: Iterable[NetworkIntelSignal]) -> List[RiskEvidence]:
    return [
        RiskEvidence(
            source="network_intelligence",
            code=signal.code,
            label=signal.label,
            score=signal.weight,
            evidence=signal.evidence,
        )
        for signal in signals
    ]


def apply_risk_engine(input_type: str, content: str, result: ScanResult) -> ScanResult:
    """Assemble the baseline evidence-based result before optional network metadata."""
    ai_score = max(0, min(int(result.confidence_score), 100))
    result.ai_confidence_score = ai_score
    result.scoring_version = SCORING_VERSION

    if input_type != "url":
        result.deterministic_score = 0
        result.risk_evidence = []
        return result

    signals = analyze_url(content)
    deterministic = url_signal_score(signals)
    ai_support = round(ai_score * 0.25)
    final_score = min(100, deterministic + ai_support)

    if any(signal.code == "brand_impersonation" for signal in signals):
        final_score = max(final_score, 65)

    result.confidence_score = final_score
    result.deterministic_score = deterministic
    result.threat_level = score_to_level(final_score)
    result.risk_evidence = _url_evidence(signals)
    return result


def apply_network_intelligence(result: ScanResult, signals: Iterable[NetworkIntelSignal]) -> ScanResult:
    """Add bounded DNS/TLS/RDAP evidence without allowing network failures to imply safety.

    Network metadata contributes at most 25 additional deterministic points. Positive
    metadata such as valid TLS and public DNS is displayed for transparency but carries
    zero negative-risk weight: HTTPS alone is never treated as proof that a site is safe.
    """
    signal_list = list(signals)
    network_points = min(25, sum(max(0, signal.weight) for signal in signal_list))
    result.deterministic_score = min(100, result.deterministic_score + network_points)
    result.confidence_score = min(100, result.confidence_score + network_points)
    result.threat_level = score_to_level(result.confidence_score)
    result.risk_evidence.extend(_network_evidence(signal_list))
    result.scoring_version = SCORING_VERSION
    return result
