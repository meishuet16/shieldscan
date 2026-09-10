from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.services.lancedb_service import build_lancedb_index
from app.services.rag_service import THREAT_INTEL_CORPUS


def main() -> None:
    count = build_lancedb_index(THREAT_INTEL_CORPUS)
    print(f"Built ShieldScan local threat-intelligence index with {count} record(s).")


if __name__ == "__main__":
    main()
