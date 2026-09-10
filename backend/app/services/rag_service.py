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

# Versioned, provenance-bearing corpus stored as JSON so it can be audited and
# re-indexed independently from retrieval code.
THREAT_INTEL_CORPUS = load_threat_intel_corpus()


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


def search_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    """Retrieve sourced threat intelligence through a provider-agnostic interface.

    Providers:
      - lancedb (default): local semantic vector retrieval, no account/API key required
      - vertex: optional managed Vertex AI Search provider
      - local: transparent deterministic keyword fallback

    Retrieval failures never become evidence that content is safe. Any unavailable
    provider degrades to the provenance-bearing local corpus and logs the condition.
    """
    provider = os.getenv("SHIELDSCAN_RETRIEVAL_PROVIDER", "lancedb").strip().lower()

    if provider == "lancedb":
        try:
            matches = search_lancedb_threat_intelligence(content, limit=limit)
            if matches:
                return matches
            logger.info("LanceDB returned no semantic matches; using local fallback")
        except LanceDBNotReady as exc:
            logger.info("Local semantic retrieval not ready: %s", exc)
        except Exception:
            logger.exception("LanceDB retrieval failed; using local fallback")

    elif provider == "vertex":
        try:
            matches = search_vertex_threat_intelligence(content, limit=limit)
            if matches:
                return matches
            logger.info("Vertex AI Search returned no sourced matches; using local fallback")
        except VertexSearchNotConfigured as exc:
            logger.warning("Vertex AI Search requested but not configured: %s", exc)
        except Exception:
            logger.exception("Vertex AI Search failed; using local fallback")

    elif provider != "local":
        logger.warning("Unknown retrieval provider '%s'; using local fallback", provider)

    return search_local_threat_intelligence(content, limit=limit)


def search_rag_database(content: str, threat_level: str | None = None) -> List[ThreatIntelMatch]:
    """Compatibility alias. Prefer search_threat_intelligence in new code."""
    return search_threat_intelligence(content)
