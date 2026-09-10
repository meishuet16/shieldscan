from app.services.lancedb_service import build_lancedb_index
from app.services.rag_service import THREAT_INTEL_CORPUS


def main() -> None:
    count = build_lancedb_index(THREAT_INTEL_CORPUS)
    print(f"Built ShieldScan local threat-intelligence index with {count} record(s).")


if __name__ == "__main__":
    main()
