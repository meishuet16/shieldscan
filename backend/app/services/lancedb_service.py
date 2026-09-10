import logging
import os
from functools import lru_cache
from pathlib import Path
from typing import Iterable, List

from app.models.scan import ThreatIntelMatch

logger = logging.getLogger(__name__)

BACKEND_ROOT = Path(__file__).resolve().parents[2]
_raw_db_path = Path(os.getenv("SHIELDSCAN_LANCEDB_PATH", "data/lancedb"))
DEFAULT_DB_PATH = _raw_db_path if _raw_db_path.is_absolute() else BACKEND_ROOT / _raw_db_path
DEFAULT_TABLE_NAME = os.getenv("SHIELDSCAN_LANCEDB_TABLE", "threat_intel")
DEFAULT_EMBEDDING_MODEL = os.getenv(
    "SHIELDSCAN_EMBEDDING_MODEL",
    "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
)
MIN_SEMANTIC_SIMILARITY = float(os.getenv("SHIELDSCAN_MIN_SEMANTIC_SIMILARITY", "0.35"))


class LanceDBNotReady(RuntimeError):
    pass


def _load_dependencies():
    try:
        import lancedb  # type: ignore
        from sentence_transformers import SentenceTransformer  # type: ignore
    except ImportError as exc:
        raise LanceDBNotReady(
            "Local semantic retrieval dependencies are missing. "
            "Install backend/requirements-rag.txt."
        ) from exc
    return lancedb, SentenceTransformer


@lru_cache(maxsize=1)
def _embedding_model():
    _, SentenceTransformer = _load_dependencies()
    return SentenceTransformer(DEFAULT_EMBEDDING_MODEL)


def _record_text(record: dict) -> str:
    keywords = ", ".join(record.get("keywords", []))
    return "\n".join(
        part
        for part in [
            record.get("title", ""),
            record.get("category", ""),
            record.get("summary", ""),
            keywords,
        ]
        if part
    )


def build_lancedb_index(records: Iterable[dict]) -> int:
    """Build/replace the local semantic threat-intelligence index."""
    lancedb, _ = _load_dependencies()
    model = _embedding_model()
    rows = []

    for record in records:
        text = _record_text(record)
        vector = model.encode(text, normalize_embeddings=True).tolist()
        rows.append(
            {
                "id": record["id"],
                "title": record["title"],
                "category": record["category"],
                "summary": record["summary"],
                "source_name": record["source_name"],
                "source_url": record.get("source_url") or "",
                "evidence_role": record.get("evidence_role", "threat_pattern"),
                "keywords": record.get("keywords", []),
                "text": text,
                "vector": vector,
            }
        )

    if not rows:
        raise ValueError("Cannot build an empty threat-intelligence index")

    DEFAULT_DB_PATH.mkdir(parents=True, exist_ok=True)
    db = lancedb.connect(str(DEFAULT_DB_PATH))
    db.create_table(DEFAULT_TABLE_NAME, data=rows, mode="overwrite")
    return len(rows)


def search_lancedb_threat_intelligence(content: str, limit: int = 3) -> List[ThreatIntelMatch]:
    """Run local semantic retrieval with a minimum similarity floor."""
    if not content.strip():
        return []

    lancedb, _ = _load_dependencies()
    if not DEFAULT_DB_PATH.exists():
        raise LanceDBNotReady(
            f"Local LanceDB index not found at {DEFAULT_DB_PATH}. "
            "Run: python scripts/build_threat_index.py"
        )

    db = lancedb.connect(str(DEFAULT_DB_PATH))
    try:
        table = db.open_table(DEFAULT_TABLE_NAME)
    except Exception as exc:
        raise LanceDBNotReady(
            f"LanceDB table '{DEFAULT_TABLE_NAME}' is missing. "
            "Run: python scripts/build_threat_index.py"
        ) from exc

    model = _embedding_model()
    query_vector = model.encode(content, normalize_embeddings=True).tolist()
    rows = table.search(query_vector).limit(limit).to_list()

    matches: List[ThreatIntelMatch] = []
    for row in rows:
        distance = float(row.get("_distance", 0.0) or 0.0)
        similarity = 1.0 / (1.0 + max(distance, 0.0))
        if similarity < MIN_SEMANTIC_SIMILARITY:
            continue
        matches.append(
            ThreatIntelMatch(
                id=str(row["id"]),
                title=str(row["title"]),
                category=str(row["category"]),
                source_name=str(row["source_name"]),
                source_url=str(row.get("source_url") or "") or None,
                matched_terms=[],
                summary=str(row["summary"]),
                retrieval_method="lancedb-semantic-v2",
                evidence_role=str(row.get("evidence_role") or "threat_pattern"),
                retrieval_score=round(similarity, 4),
            )
        )
    return matches
