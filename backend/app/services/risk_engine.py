from typing import Iterable, List

from app.models.scan import RiskEvidence, ScanResult, ThreatLevel
from app.services.url_intelligence import UrlSignal, analyze_url, url_signal_score


SCORING_VERSION = "shieldscan-v2.1"


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


def apply_risk_engine(input_type: str, content: str, result: ScanResult) -> ScanResult:
    """Turn model output plus deterministic signals into an auditable result.

    v2.1 intentionally treats the LLM score as a supporting signal, not calibrated
    probability. URL scans receive deterministic lexical/domain evidence. Text/image
    scans preserve the model score until dedicated classifiers/evaluation are added.
    """
    ai_score = max(0, min(int(result.confidence_score), 100))
    result.ai_confidence_score = ai_score
    result.scoring_version = SCORING_VERSION

    if input_type != "url":
        result.deterministic_score = 0
        result.risk_evidence = []
        return result

    signals = analyze_url(content)
    deterministic = url_signal_score(signals)

    # Deterministic evidence is the primary URL signal. The LLM may contribute up to
    # 25 points, preventing a confident model answer from overwhelming concrete checks.
    ai_support = round(ai_score * 0.25)
    final_score = min(100, deterministic + ai_support)

    # An explicit brand-impersonation signal should never be presented as SAFE/LOW.
    if any(signal.code == "brand_impersonation" for signal in signals):
        final_score = max(final_score, 65)

    result.confidence_score = final_score
    result.deterministic_score = deterministic
    result.threat_level = score_to_level(final_score)
    result.risk_evidence = _url_evidence(signals)
    return result
