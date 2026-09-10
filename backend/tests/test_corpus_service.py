from app.services.corpus_service import load_threat_intel_corpus


def test_versioned_corpus_has_unique_sourced_records():
    records = load_threat_intel_corpus()

    ids = [record["id"] for record in records]
    assert len(ids) == len(set(ids))
    assert len(records) >= 7
    assert all(record["source_url"].startswith("https://") for record in records)
    assert all(record["source_name"] for record in records)


def test_corpus_contains_dated_2026_bnm_alert_update():
    records = load_threat_intel_corpus()
    dated = [record for record in records if record.get("published_at") == "2026-08-03"]

    assert dated
    assert dated[0]["agency"] == "BNM"
    assert dated[0]["category"] == "investment-scam"
