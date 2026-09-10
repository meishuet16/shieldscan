"""Refresh official PDRM scam-alert posts into ShieldScan's threat corpus.

Only the official PDRM Scam Alert listing is fetched. Linked article URLs are retained as
provenance and may be fetched only when they remain on rmp.gov.my; no third-party links
inside posts are followed.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import urljoin, urlparse

import httpx
from bs4 import BeautifulSoup

SOURCE_URL = "https://www.rmp.gov.my/laman-utama/peringatan/alert-peringatan"
BACKEND_ROOT = Path(__file__).resolve().parents[1]
CORPUS_PATH = BACKEND_ROOT / "data" / "threat_intel.json"
ALLOWED_HOSTS = {"www.rmp.gov.my", "rmp.gov.my"}


def _slug(value: str) -> str:
    return re.sub(r"[^A-Z0-9]+", "-", value.upper()).strip("-")[:72]


def _clean(text: str) -> str:
    return " ".join(text.split())


def _category(title: str, summary: str) -> str:
    text = f"{title} {summary}".lower()
    if any(term in text for term in ["kerja", "job", "part-time", "sambilan"]):
        return "job-scam"
    if any(term in text for term in ["keldai akaun", "mule", "akaun bank"]):
        return "mule-account"
    if any(term in text for term in ["menyamar", "impersonat", "kenalan", "bank negara"]):
        return "impersonation-and-social-engineering"
    if any(term in text for term in ["pelaburan", "investment", "forex", "crypto"]):
        return "investment-scam"
    return "scam-alert"


def parse_pdrm_alert_listing(html: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    records: list[dict] = []
    seen: set[str] = set()

    for anchor in soup.find_all("a", href=True):
        title = _clean(anchor.get_text(" ", strip=True))
        href = urljoin(SOURCE_URL, anchor["href"])
        parsed = urlparse(href)
        if parsed.hostname not in ALLOWED_HOSTS:
            continue
        if "news-detail" not in parsed.path and "alert-peringatan" not in parsed.path:
            continue
        if not title or title.lower() in {"baca lagi", "read more"}:
            continue

        container = anchor.find_parent(["article", "li", "div"]) or anchor.parent
        context = _clean(container.get_text(" ", strip=True)) if container else title
        if title in seen:
            continue
        seen.add(title)

        date_match = re.search(
            r"\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},\s+\d{4}\b",
            context,
            flags=re.IGNORECASE,
        )
        summary = context
        if summary.startswith(title):
            summary = summary[len(title):].strip(" :-")
        if len(summary) > 360:
            summary = summary[:357].rstrip() + "..."

        keywords = [
            token.lower()
            for token in re.findall(r"[A-Za-z0-9]+", title)
            if len(token) >= 5
        ]
        records.append(
            {
                "id": f"PDRM-{_slug(title)}",
                "title": title,
                "category": _category(title, summary),
                "summary": summary or title,
                "keywords": list(dict.fromkeys(keywords)),
                "source_name": "Polis Diraja Malaysia — Scam Alert",
                "source_url": href,
                "published_at": date_match.group(0) if date_match else None,
                "agency": "PDRM",
            }
        )

    return records


def merge_records(existing: list[dict], incoming: list[dict]) -> list[dict]:
    merged = {record["id"]: record for record in existing}
    for record in incoming:
        merged[record["id"]] = record
    return sorted(merged.values(), key=lambda item: (item.get("agency", ""), item["id"]))


def main() -> None:
    with httpx.Client(timeout=20.0, follow_redirects=True, headers={"User-Agent": "ShieldScanThreatIntel/1.0"}) as client:
        response = client.get(SOURCE_URL)
        response.raise_for_status()

    incoming = parse_pdrm_alert_listing(response.text)
    if not incoming:
        raise RuntimeError("PDRM scam-alert parser returned zero records; page structure may have changed")

    existing = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    merged = merge_records(existing, incoming)
    CORPUS_PATH.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Ingested {len(incoming)} PDRM alert record(s); corpus now has {len(merged)} record(s).")


if __name__ == "__main__":
    main()
