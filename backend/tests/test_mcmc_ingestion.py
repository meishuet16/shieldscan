from scripts.ingest_mcmc_notices import record_from_notice


def test_mcmc_notice_becomes_threat_pattern_record():
    spec = {
        "id": "MCMC-TEST",
        "url": "https://www.mcmc.gov.my/example.pdf",
        "title": "Scam SMS notice",
        "published_at": "2023-06-24",
        "category": "phishing-and-scam-sms",
    }
    text = (
        "Kandungan SMS berunsur penipuan termasuk pautan untuk klik, "
        "memohon maklumat peribadi dan nombor talian untuk dihubungi."
    )

    record = record_from_notice(spec, text)

    assert record["agency"] == "MCMC"
    assert record["evidence_role"] == "threat_pattern"
    assert record["source_url"].startswith("https://www.mcmc.gov.my/")
    assert "sms" in record["keywords"]
    assert "pautan" in record["keywords"]


def test_mcmc_notice_without_expected_signals_is_rejected():
    spec = {
        "id": "MCMC-TEST",
        "url": "https://www.mcmc.gov.my/example.pdf",
        "title": "Unrelated notice",
        "published_at": None,
        "category": "context",
    }

    try:
        record_from_notice(spec, "General administrative announcement only")
    except ValueError as exc:
        assert "expected scam/SMS indicators" in str(exc)
    else:
        raise AssertionError("Expected unrelated MCMC notice to be rejected")
