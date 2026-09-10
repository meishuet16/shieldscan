"""Refresh allowlisted official MCMC scam-related notices into ShieldScan's corpus.

Only explicitly configured mcmc.gov.my documents are fetched. This adapter does not crawl
arbitrary links from MCMC documents and never follows third-party URLs mentioned inside them.
"""
from __future__ import annotations

import io
import json
import re
from pathlib import Path
from urllib.parse import urlparse

import httpx
from pypdf import PdfReader

BACKEND_ROOT = Path(__file__).resolve().parents[1]
CORPUS_PATH = BACKEND_ROOT / "data" / "threat_intel.json"
ALLOWED_HOSTS = {"www.mcmc.gov.my", "mcmc.gov.my"}

SOURCES = [
    {
        "id": "MCMC-SCAM-SMS-BLOCKING-2023-06-24",
        "url": "https://www.mcmc.gov.my/skmmgovmy/media/General/PressRelease/NOTIS-AWAM-Sekatan-SMS-Fasa-Akhir.pdf",
        "title": "MCMC scam-SMS blocking indicators",
        "published_at": "2023-06-24",
        "category": "phishing-and-scam-sms",
    },
]


def _clean(text: str) -> str:
    return " ".join(text.split())


def extract_pdf_text(payload: bytes) -> str:
    reader = PdfReader(io.BytesIO(payload))
    return _clean(" ".join(page.extract_text() or "" for page in reader.pages))


def record_from_notice(spec: dict, text: str) -> dict:
    lower = text.lower()
    signal_terms = [
        term
        for term in [
            "sms", "pautan", "klik", "maklumat peribadi", "personal information",
            "nombor talian", "phone number", "penipuan", "scam", "phishing",
        ]
        if term in lower
    ]
    if not signal_terms:
        raise ValueError(f"MCMC notice {spec['id']} did not contain expected scam/SMS indicators")

    summary = (
        "MCMC identified scam-prone SMS content patterns including messages that direct users "
        "to click links, request personal information, or provide phone numbers to contact. "
        "These are contextual threat indicators and do not by themselves prove that a specific message is fraudulent."
    )
    return {
        "id": spec["id"],
        "title": spec["title"],
        "category": spec["category"],
        "summary": summary,
        "keywords": list(dict.fromkeys(signal_terms + ["click link", "sms scam"])),
        "source_name": "Malaysian Communications and Multimedia Commission — Scam SMS Blocking Notice",
        "source_url": spec["url"],
        "published_at": spec["published_at"],
        "agency": "MCMC",
        "evidence_role": "threat_pattern",
    }


def merge_records(existing: list[dict], incoming: list[dict]) -> list[dict]:
    merged = {record["id"]: record for record in existing}
    for record in incoming:
        merged[record["id"]] = record
    return sorted(merged.values(), key=lambda item: (item.get("agency", ""), item["id"]))


def main() -> None:
    incoming: list[dict] = []
    with httpx.Client(timeout=25.0, follow_redirects=True, headers={"User-Agent": "ShieldScanThreatIntel/1.0"}) as client:
        for spec in SOURCES:
            parsed = urlparse(spec["url"])
            if parsed.hostname not in ALLOWED_HOSTS or parsed.scheme != "https":
                raise RuntimeError(f"Refusing non-MCMC source: {spec['url']}")
            response = client.get(spec["url"])
            response.raise_for_status()
            content_type = response.headers.get("content-type", "").lower()
            if "pdf" not in content_type and not spec["url"].lower().endswith(".pdf"):
                raise RuntimeError(f"Unexpected MCMC document type for {spec['url']}")
            incoming.append(record_from_notice(spec, extract_pdf_text(response.content)))

    existing = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    merged = merge_records(existing, incoming)
    CORPUS_PATH.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Ingested {len(incoming)} MCMC notice record(s); corpus now has {len(merged)} record(s).")


if __name__ == "__main__":
    main()
