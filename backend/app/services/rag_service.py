import os
from typing import List

# Known Malaysian fraud patterns database
# In production, this connects to Vertex AI Search with PDRM/BNM/MCMC datasets
MALAYSIA_FRAUD_DB = [
    {
        "id": "PDRM-2024-001",
        "type": "Macau Scam",
        "pattern": "impersonation of police/bank officer",
        "keywords": ["polis", "tahan", "akaun", "sekat", "BNM", "transfer"],
        "source": "PDRM Cybercrime Division"
    },
    {
        "id": "BNM-2024-045",
        "type": "Banking Phishing",
        "pattern": "fake Maybank2u / CIMB login page",
        "keywords": ["maybank2u", "cimb", "verify", "suspend", "login", "secure-maybank"],
        "source": "Bank Negara Malaysia"
    },
    {
        "id": "MCMC-2024-112",
        "type": "WhatsApp Prize Scam",
        "pattern": "fake prize/lottery notification",
        "keywords": ["tahniah", "menang", "hadiah", "RM", "klik", "tuntut", "lucky winner"],
        "source": "MCMC Consumer Forum"
    },
    {
        "id": "PDRM-2024-078",
        "type": "Investment Scam",
        "pattern": "fake high-return investment platform",
        "keywords": ["untung", "pelaburan", "ROI", "forex", "crypto", "guaranteed return"],
        "source": "PDRM Commercial Crime Investigation Department"
    },
    {
        "id": "BNM-2024-201",
        "type": "Loan Scam",
        "pattern": "fake personal loan offer",
        "keywords": ["pinjaman", "loan", "approval", "no credit check", "bayar deposit"],
        "source": "Bank Negara Malaysia"
    },
]


def search_rag_database(content: str, threat_level: str) -> List[str]:
    """
    Search the Malaysian fraud database for matching patterns.
    In production: connects to Vertex AI Search engine.
    
    Returns list of matching fraud case descriptions.
    """
    matches = []
    content_lower = content.lower()

    # Check for Vertex AI Search integration
    vertex_engine_id = os.environ.get("VERTEX_SEARCH_ENGINE_ID", "")
    if vertex_engine_id:
        # TODO: Integrate Vertex AI Search Discovery Engine
        # from google.cloud import discoveryengine_v1beta
        # client = discoveryengine_v1beta.SearchServiceClient()
        # ... vertex AI search call
        pass

    # Local pattern matching fallback
    for case in MALAYSIA_FRAUD_DB:
        matched_keywords = [kw for kw in case["keywords"] if kw.lower() in content_lower]
        if matched_keywords:
            matches.append(
                f"[{case['id']}] {case['type']}: {case['pattern']} "
                f"(Source: {case['source']})"
            )

    # If HIGH/CRITICAL threat, always add general advisory
    if threat_level in ["HIGH", "CRITICAL"] and not matches:
        matches.append(
            "[ADVISORY] Report to PDRM Cybercrime: 03-2266 2222 or "
            "BNM BNMTELELINK: 1-300-88-5465"
        )

    return matches[:3]  # Return top 3 matches
