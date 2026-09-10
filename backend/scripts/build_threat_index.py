from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.services.corpus_service import load_threat_intel_corpus
from app.services.lancedb_service import build_lancedb_index


def main() -> None:
    records = load_threat_intel_corpus()
    count = build_lancedb_index(records)
    print(f"Built ShieldScan local threat-intelligence index with {count} record(s).")


if __name__ == "__main__":
    main()
