import logging
import os
from typing import List

from app.models.scan import ThreatIntelMatch
from app.services.corpus_service import load_threat_intel_corpus
from app.services.lancedb_service import LanceDBNotReady, search_lancedb_threat_intelligence
from app.services.vertex_search_service import (
    VertexSearchNotConfigured,
    search_vertex_threat_intelligence,
)

logger = logging.getLogger(__name__)

THREAT_INTEL_CORPUS = load_threat_intel_corpus()
LOCAL_KEYWORD_MIN_SCORE = float(os.getenv("SHIELDSCAN_LOCAL_KEYWORD_MIN_SCORE", "0.20"))


def _threat_pattern_only(matches: List[ThreatIntelMatch], limit: int) -> List[ThreatIntelMatch]:
    return [match for match in matches if match.evidence_role == "threat_pattern"][:limit]


def search_local_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    content_lower = content.lower()
    ranked = []
    for record in THREAT_INTEL_CORPUS:
        if record.get("evidence_role") != "threat_pattern":
            continue
        matched_terms = [term for term in record["keywords"] if term.lower() in content_lower]
        if not matched_terms:
            continue
        score = min(1.0, len(matched_terms) / max(3, len(record["keywords"])))
        if score < LOCAL_KEYWORD_MIN_SCORE:
            continue
        ranked.append((score, len(matched_terms), record, matched_terms))

    ranked.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return [
        ThreatIntelMatch(
            id=record["id"],
            title=record["title"],
            category=record["category"],
            source_name=record["source_name"],
            source_url=record["source_url"],
            matched_terms=matched_terms,
            summary=record["summary"],
            retrieval_method="local-keyword-v3",
            evidence_role=record["evidence_role"],
            retrieval_score=round(score, 4),
        )
        for score, _, record, matched_terms in ranked[:limit]
    ]


def search_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    provider = os.getenv("SHIELDSCAN_RETRIEVAL_PROVIDER", "lancedb").strip().lower()

    if provider == "lancedb":
        try:
            matches = _threat_pattern_only(
                search_lancedb_threat_intelligence(content, limit=max(limit * 4, limit)),
                limit,
            )
            if matches:
                return matches
            logger.info("LanceDB returned no qualifying threat-pattern matches; using local fallback")
        except LanceDBNotReady as exc:
            logger.info("Local semantic retrieval not ready: %s", exc)
        except Exception:
            logger.exception("LanceDB retrieval failed; using local fallback")

    elif provider == "vertex":
        try:
            matches = _threat_pattern_only(
                search_vertex_threat_intelligence(content, limit=max(limit * 4, limit)),
                limit,
            )
            if matches:
                return matches
            logger.info("Vertex AI Search returned no qualifying sourced matches; using local fallback")
        except VertexSearchNotConfigured as exc:
            logger.warning("Vertex AI Search requested but not configured: %s", exc)
        except Exception:
            logger.exception("Vertex AI Search failed; using local fallback")

    elif provider != "local":
        logger.warning("Unknown retrieval provider '%s'; using local fallback", provider)

    return search_local_threat_intelligence(content, limit=limit)


def search_rag_database(content: str, threat_level: str | None = None) -> List[ThreatIntelMatch]:
    return search_threat_intelligence(content)
