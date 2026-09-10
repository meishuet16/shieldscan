from app.services import request_guardrails as guardrails


def setup_function():
    guardrails.reset_rate_limits()


def test_request_size_limit_rejects_oversized_body(monkeypatch):
    monkeypatch.setattr(guardrails, "MAX_REQUEST_BYTES", 100)
    assert guardrails.request_too_large("101") is True
    assert guardrails.request_too_large("100") is False


def test_invalid_content_length_is_rejected():
    assert guardrails.request_too_large("not-a-number") is True


def test_sliding_window_rate_limit(monkeypatch):
    monkeypatch.setattr(guardrails, "RATE_LIMIT_REQUESTS", 2)
    monkeypatch.setattr(guardrails, "RATE_LIMIT_WINDOW_SECONDS", 60)

    assert guardrails.allow_request("client-a", now=0)[0] is True
    assert guardrails.allow_request("client-a", now=1)[0] is True

    allowed, retry_after = guardrails.allow_request("client-a", now=2)
    assert allowed is False
    assert retry_after > 0

    assert guardrails.allow_request("client-a", now=61)[0] is True


def test_rate_limits_are_isolated_per_client(monkeypatch):
    monkeypatch.setattr(guardrails, "RATE_LIMIT_REQUESTS", 1)
    assert guardrails.allow_request("client-a", now=0)[0] is True
    assert guardrails.allow_request("client-b", now=0)[0] is True
