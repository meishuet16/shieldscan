import pytest

from app.services.network_safety import assert_safe_public_target, classify_addresses


def test_blocks_loopback_and_private_addresses():
    results = classify_addresses("example.test", ["127.0.0.1", "10.0.0.5", "192.168.1.2"])
    assert all(not item.is_public for item in results)


def test_allows_public_addresses():
    results = classify_addresses("example.com", ["8.8.8.8", "1.1.1.1"])
    assert all(item.is_public for item in results)


def test_rejects_mixed_public_and_private_resolution():
    with pytest.raises(ValueError):
        assert_safe_public_target("mixed.example", ["8.8.8.8", "127.0.0.1"])


def test_rejects_invalid_ip():
    with pytest.raises(ValueError):
        assert_safe_public_target("bad.example", ["not-an-ip"])
