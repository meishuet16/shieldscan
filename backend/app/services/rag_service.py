from typing import List

from app.models.scan import ThreatIntelMatch


# Curated seed corpus. Every record is intentionally explicit about provenance.
# This is NOT labelled as RAG: it is deterministic local retrieval that provides a
# stable fallback while the external ingestion/indexing pipeline is built.
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
        "summary": "PDRM publishes current scam alerts and advises the public to verify suspicious account or phone details through official channels.",
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


def search_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    """Retrieve provenance-bearing threat intelligence from the local seed corpus.

    This deliberately uses transparent keyword retrieval instead of pretending that a
    vector/Vertex index exists. The API shape is already suitable for replacing this
    implementation with hybrid/vector retrieval later without changing scan clients.
    """
    content_lower = content.lower()
    ranked = []

    for record in THREAT_INTEL_CORPUS:
        matched_terms = [term for term in record["keywords"] if term.lower() in content_lower]
        if not matched_terms:
            continue
        ranked.append((len(matched_terms), record, matched_terms))

    ranked.sort(key=lambda item: item[0], reverse=True)
    return [
        ThreatIntelMatch(
            id=record["id"],
            title=record["title"],
            category=record["category"],
            source_name=record["source_name"],
            source_url=record["source_url"],
            matched_terms=matched_terms,
            summary=record["summary"],
            retrieval_method="local-keyword-v1",
        )
        for _, record, matched_terms in ranked[:limit]
    ]


# Backwards-compatible alias while older callers are migrated.
def search_rag_database(content: str, threat_level: str | None = None) -> List[ThreatIntelMatch]:
    return search_threat_intelligence(content)
