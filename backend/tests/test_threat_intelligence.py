from app.services.rag_service import search_threat_intelligence


def test_returns_structured_source_provenance_for_phishing():
    matches = search_threat_intelligence(
        "Your Maybank2u account is suspended. Login and verify now."
    )

    assert matches
    top = matches[0]
    assert top.source_name.startswith("Bank Negara Malaysia")
    assert top.source_url and top.source_url.startswith("https://www.bnm.gov.my/")
    assert top.retrieval_method == "local-keyword-v1"
    assert "maybank2u" in top.matched_terms


def test_returns_empty_for_unrelated_benign_text():
    matches = search_threat_intelligence("Lunch at 12.30 near the library")
    assert matches == []


def test_ranks_more_keyword_matches_first():
    matches = search_threat_intelligence(
        "Guaranteed investment return from forex and crypto pelaburan platform"
    )

    assert matches
    assert matches[0].category == "investment-scam"
