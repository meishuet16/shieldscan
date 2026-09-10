import logging
import os
from typing import List

from app.models.scan import ThreatIntelMatch
from app.services.vertex_search_service import (
    VertexSearchNotConfigured,
    search_vertex_threat_intelligence,
)

logger = logging.getLogger(__name__)

# Curated provenance-bearing fallback corpus. This remains available for local
# development and when the managed retrieval provider is unavailable.
THREAT_INTEL_CORPUS = [
    {
        "id": "BNM-PHISHING",
        "title": "Phishing guidance",
        "category": "phishing",
        "summary": "Fraudulent links and lookalike websites may be used to steal banking credentials.",
        "keywords": ["maybank2u", "cimb", "login", "verify", "suspend", "bank", "credential", "phishing"],
        "source_name": "Bank Negara Malaysia — Financial Fraud Alerts",
        "source_url": "https://www.bnm.gov.my/financial-fraud-alerts",
    },
    {
        "id": "BNM-MOBILE-APP-SCAM",
        "title": "Mobile application scam guidance",
        "category": "malicious-app",
        "summary": "Suspicious third-party applications and links can expose transaction alerts, OTPs and device access.",
        "keywords": ["apk", "download app", "install app", "otp", "sms", "whatsapp", "telegram"],
        "source_name": "Bank Negara Malaysia — Financial Fraud Alerts",
        "source_url": "https://www.bnm.gov.my/financial-fraud-alerts",
    },
    {
        "id": "BNM-INVESTMENT-ALERT",
        "title": "Financial Consumer Alert",
        "category": "investment-scam",
        "summary": "BNM maintains an alert list for entities or schemes that may be represented as licensed or regulated when they are not.",
        "keywords": ["investment", "pelaburan", "forex", "crypto", "return", "untung", "guaranteed", "licensed"],
        "source_name": "Bank Negara Malaysia — Financial Consumer Alert List",
        "source_url": "https://www.bnm.gov.my/financial-consumer-alert-list",
    },
    {
        "id": "PDRM-SCAM-ALERT",
        "title": "Scam Alert",
        "category": "impersonation-and-social-engineering",
        "summary": "PDRM publishes scam alerts and advises the public to verify suspicious details through official channels.",
        "keywords": ["polis", "pdrm", "guru", "teacher", "qr", "akaun", "account", "transfer", "scammer"],
        "source_name": "Polis Diraja Malaysia — Scam Alert",
        "source_url": "https://www.rmp.gov.my/laman-utama/peringatan/alert-peringatan",
    },
    {
        "id": "BNM-MULE-ACCOUNT",
        "title": "Mule account guidance",
        "category": "mule-account",
        "summary": "Accounts offered for rent or used to receive and transfer suspicious funds can expose users to financial and legal harm.",
        "keywords": ["rent account", "sewa akaun", "atm card", "bank account", "transfer funds", "mule"],
        "source_name": "Bank Negara Malaysia — Financial Fraud Alerts",
        "source_url": "https://www.bnm.gov.my/muleaccount",
    },
]


def search_local_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    content_lower = content.lower()
    ranked = []
    for record in THREAT_INTEL_CORPUS:
        matched_terms = [term for term in record["keywords"] if term.lower() in content_lower]
        if matched_terms:
            ranked.append((len(matched_terms), record, matched_terms))
    ranked.sort(key=lambda item: item[0], reverse=True)
    return [
        ThreatIntelMatch(
            id=record["id"], title=record["title"], category=record["category"],
            source_name=record["source_name"], source_url=record["source_url"],
            matched_terms=matched_terms, summary=record["summary"],
            retrieval_method="local-keyword-v1",
        )
        for _, record, matched_terms in ranked[:limit]
    ]


def search_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    """Retrieve sourced intelligence, preferring Vertex AI Search when configured.

    SHIELDSCAN_RETRIEVAL_PROVIDER=vertex enables managed semantic retrieval. Provider
    errors fail visibly in logs and degrade to the local provenance-bearing corpus;
    they never turn a failed lookup into evidence that content is safe.
    """
    provider = os.getenv("SHIELDSCAN_RETRIEVAL_PROVIDER", "local").strip().lower()
    if provider == "vertex":
        try:
            matches = search_vertex_threat_intelligence(content, limit=limit)
            if matches:
                return matches
            logger.info("Vertex AI Search returned no sourced matches; using local fallback")
        except VertexSearchNotConfigured as exc:
            logger.warning("Vertex AI Search requested but not configured: %s", exc)
        except Exception:
            logger.exception("Vertex AI Search failed; using local fallback")
    return search_local_threat_intelligence(content, limit=limit)


def search_rag_database(content: str, threat_level: str | None = None) -> List[ThreatIntelMatch]:
    """Compatibility alias. Prefer search_threat_intelligence in new code."""
    return search_threat_intelligence(content)
