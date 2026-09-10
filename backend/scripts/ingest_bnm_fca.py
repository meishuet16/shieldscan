"""Refresh BNM Financial Consumer Alert entities into ShieldScan's threat corpus.

This script fetches only the official BNM FCA page supplied below. It does not follow
or request any third-party URLs contained in the alert table; those URLs are treated
as untrusted strings and stored as evidence only.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Iterable

import httpx
from bs4 import BeautifulSoup

SOURCE_URL = "https://www.bnm.gov.my/financial-consumer-alert-list"
BACKEND_ROOT = Path(__file__).resolve().parents[1]
CORPUS_PATH = BACKEND_ROOT / "data" / "threat_intel.json"


def _slug(value: str) -> str:
    return re.sub(r"[^A-Z0-9]+", "-", value.upper()).strip("-")[:72]


def parse_bnm_fca_html(html: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    rows: list[dict] = []

    for tr in soup.select("table tr"):
        cells = [" ".join(cell.stripped_strings) for cell in tr.find_all(["td", "th"])]
        if len(cells) < 3 or "Date Added" in cells[2] or "Name of unauthorised" in cells[0]:
            continue

        name = cells[0].strip()
        website_text = cells[1].strip()
        date_text = cells[2].strip()
        if not name:
            continue

        links = [a.get("href", "").strip() for a in tr.select("td:nth-of-type(2) a[href]")]
        links = [link for link in links if link.startswith(("http://", "https://"))]
        clone = "potential clone entity" in name.lower()
        category = "clone-entity" if clone else "unauthorised-financial-entity"
        keywords = [name]
        keywords.extend(token for token in re.split(r"\s+", name.lower()) if len(token) >= 5)

        rows.append(
            {
                "id": f"BNM-FCA-{_slug(name)}",
                "title": name,
                "category": category,
                "summary": (
                    f"Bank Negara Malaysia lists {name} on its Financial Consumer Alert List. "
                    "The list is a public guide to entities or schemes identified as not authorised by BNM "
                    "to offer financial products or services regulated by BNM."
                ),
                "keywords": list(dict.fromkeys(keywords)),
                "source_name": "Bank Negara Malaysia — Financial Consumer Alert List",
                "source_url": SOURCE_URL,
                "published_at": date_text or None,
                "agency": "BNM",
                "reported_channels": links,
                "reported_channel_text": website_text,
            }
        )
    return rows


def merge_records(existing: Iterable[dict], incoming: Iterable[dict]) -> list[dict]:
    merged = {record["id"]: record for record in existing}
    for record in incoming:
        merged[record["id"]] = record
    return sorted(merged.values(), key=lambda item: (item.get("agency", ""), item["id"]))


def main() -> None:
    with httpx.Client(timeout=20.0, follow_redirects=True, headers={"User-Agent": "ShieldScanThreatIntel/1.0"}) as client:
        response = client.get(SOURCE_URL)
        response.raise_for_status()

    incoming = parse_bnm_fca_html(response.text)
    if not incoming:
        raise RuntimeError("BNM FCA parser returned zero records; page structure may have changed")

    existing = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    merged = merge_records(existing, incoming)
    CORPUS_PATH.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Ingested {len(incoming)} BNM FCA record(s); corpus now has {len(merged)} record(s).")


if __name__ == "__main__":
    main()
