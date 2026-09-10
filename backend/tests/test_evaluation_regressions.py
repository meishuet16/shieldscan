import json
from pathlib import Path

from app.services.rag_service import search_threat_intelligence
from app.services.url_intelligence import analyze_url, url_signal_score


FIXTURE_PATH = Path(__file__).resolve().parents[1] / "evaluation" / "fixtures.json"
FIXTURES = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def test_url_evaluation_fixtures():
    for case in FIXTURES["url_cases"]:
        signals = analyze_url(case["url"])
        score = url_signal_score(signals)
        codes = {signal.code for signal in signals}

        if "expected_min_deterministic_score" in case:
            assert score >= case["expected_min_deterministic_score"], case["id"]
        if "expected_max_deterministic_score" in case:
            assert score <= case["expected_max_deterministic_score"], case["id"]
        for required in case.get("must_have", []):
            assert required in codes, f"{case['id']}: missing {required}"
        for forbidden in case.get("must_not_have", []):
            assert forbidden not in codes, f"{case['id']}: unexpected {forbidden}"


def test_retrieval_evaluation_fixtures(monkeypatch):
    monkeypatch.setenv("SHIELDSCAN_RETRIEVAL_PROVIDER", "local")

    for case in FIXTURES["retrieval_cases"]:
        matches = search_threat_intelligence(case["text"])
        categories = {match.category for match in matches}

        if case["expect_match"]:
            assert matches, f"{case['id']}: expected a sourced threat-intel match"
            expected = set(case.get("expected_categories", []))
            if expected:
                assert categories & expected, (
                    f"{case['id']}: expected one of {sorted(expected)}, got {sorted(categories)}"
                )
        else:
            assert matches == [], f"{case['id']}: false positive {matches}"

        for forbidden in case.get("forbidden_categories", []):
            assert forbidden not in categories, (
                f"{case['id']}: response/context material leaked into threat evidence"
            )
