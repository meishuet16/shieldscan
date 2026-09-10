from app.api.scan import IMAGE_RETRIEVAL_QUERY_MAX_CHARS, build_retrieval_query
from app.models.scan import FraudIndicator, InputType, ScanRequest, ScanResult, ThreatLevel


def _result(summary_en="Suspicious Maybank login message", summary_bm="Mesej login Maybank mencurigakan"):
    return ScanResult(
        threat_level=ThreatLevel.HIGH,
        confidence_score=75,
        summary_en=summary_en,
        summary_bm=summary_bm,
        indicators=[
            FraudIndicator(
                category="phishing",
                description="Requests banking login verification through a suspicious link",
                severity="high",
            )
        ],
        recommendation_en="Verify with the bank.",
        recommendation_bm="Sahkan dengan bank.",
        scan_duration_ms=100,
    )


def test_image_query_uses_semantic_text_not_base64():
    raw_base64 = "data:image/png;base64,AAAABBBBCCCC"
    request = ScanRequest(type=InputType.IMAGE, content=raw_base64)

    query = build_retrieval_query(request, _result())

    assert raw_base64 not in query
    assert "Suspicious Maybank login message" in query
    assert "phishing" in query
    assert "Requests banking login verification" in query


def test_text_query_keeps_original_content():
    request = ScanRequest(type=InputType.TEXT, content="Original suspicious SMS")
    assert build_retrieval_query(request, _result()) == "Original suspicious SMS"


def test_image_query_deduplicates_equal_summaries_and_is_bounded():
    unique_prefix = "UNIQUE_IMAGE_SUMMARY "
    long_summary = unique_prefix + ("x" * (IMAGE_RETRIEVAL_QUERY_MAX_CHARS + 500))
    request = ScanRequest(type=InputType.IMAGE, content="base64-data")
    result = _result(summary_en=long_summary, summary_bm=long_summary)

    query = build_retrieval_query(request, result)

    assert len(query) == IMAGE_RETRIEVAL_QUERY_MAX_CHARS
    assert query.count(unique_prefix) == 1


def test_empty_image_semantics_produce_empty_query():
    request = ScanRequest(type=InputType.IMAGE, content="base64-data")
    result = ScanResult(
        threat_level=ThreatLevel.SAFE,
        confidence_score=0,
        summary_en="",
        summary_bm="",
        indicators=[],
        recommendation_en="",
        recommendation_bm="",
        scan_duration_ms=1,
    )

    assert build_retrieval_query(request, result) == ""
