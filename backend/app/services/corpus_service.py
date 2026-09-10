import json
from pathlib import Path
from typing import List


DEFAULT_CORPUS_PATH = Path(__file__).resolve().parents[2] / "data" / "threat_intel.json"


def load_threat_intel_corpus(path: Path | None = None) -> List[dict]:
    """Load the versioned provenance-bearing threat-intelligence corpus.

    Keeping corpus data outside Python code makes it easier to audit, extend and rebuild
    semantic indexes without changing retrieval logic.
    """
    corpus_path = path or DEFAULT_CORPUS_PATH
    with corpus_path.open("r", encoding="utf-8") as handle:
        records = json.load(handle)

    if not isinstance(records, list) or not records:
        raise ValueError("Threat-intelligence corpus must be a non-empty JSON array")

    required = {"id", "title", "category", "summary", "keywords", "source_name", "source_url"}
    seen_ids: set[str] = set()
    for record in records:
        if not isinstance(record, dict):
            raise ValueError("Every threat-intelligence record must be an object")
        missing = required.difference(record)
        if missing:
            raise ValueError(f"Threat-intelligence record is missing fields: {sorted(missing)}")
        record_id = str(record["id"])
        if record_id in seen_ids:
            raise ValueError(f"Duplicate threat-intelligence id: {record_id}")
        seen_ids.add(record_id)
        if not str(record["source_url"]).startswith("https://"):
            raise ValueError(f"Threat-intelligence source must use HTTPS: {record_id}")

    return records
