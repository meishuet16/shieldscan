import ipaddress
import math
import re
from dataclasses import dataclass, asdict
from typing import List
from urllib.parse import urlparse


SUSPICIOUS_TLDS = {
    "xyz", "top", "click", "link", "live", "shop", "support", "work", "zip", "mov"
}

MALAYSIAN_BRANDS = {
    "maybank": ["maybank2u", "maybank"],
    "cimb": ["cimbclicks", "cimb"],
    "tng": ["touchngo", "tng"],
    "publicbank": ["publicbank", "pbebank"],
    "rhb": ["rhb"],
}

OFFICIAL_DOMAINS = {
    "maybank": {"maybank2u.com.my", "maybank.com"},
    "cimb": {"cimb.com", "cimbclicks.com.my"},
    "tng": {"touchngo.com.my", "tngdigital.com.my"},
    "publicbank": {"pbebank.com", "publicbankgroup.com"},
    "rhb": {"rhbgroup.com"},
}


@dataclass
class UrlSignal:
    code: str
    label: str
    weight: int
    evidence: str

    def model_dump(self) -> dict:
        return asdict(self)


def _normalise_url(value: str) -> str:
    value = value.strip()
    if not re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*://", value):
        value = "https://" + value
    return value


def _hostname_entropy(hostname: str) -> float:
    if not hostname:
        return 0.0
    frequencies = {ch: hostname.count(ch) / len(hostname) for ch in set(hostname)}
    return -sum(p * math.log2(p) for p in frequencies.values())


def _looks_like_ip(hostname: str) -> bool:
    try:
        ipaddress.ip_address(hostname.strip("[]"))
        return True
    except ValueError:
        return False


def analyze_url(url: str) -> List[UrlSignal]:
    """Return deterministic, explainable URL-risk signals.

    This intentionally performs no network fetch. It is safe from SSRF and works as a
    first-pass lexical/domain analysis layer before any optional reputation provider.
    """
    signals: List[UrlSignal] = []
    parsed = urlparse(_normalise_url(url))
    hostname = (parsed.hostname or "").lower().rstrip(".")

    if not hostname:
        return [UrlSignal("invalid_url", "Invalid URL", 35, "No valid hostname could be parsed")]

    if parsed.scheme != "https":
        signals.append(UrlSignal("no_https", "No HTTPS", 12, f"URL uses {parsed.scheme or 'unknown'} instead of HTTPS"))

    if parsed.username or parsed.password:
        signals.append(UrlSignal("embedded_credentials", "Embedded credentials", 35, "URL contains username/password-style authority data"))

    if parsed.port and parsed.port not in {80, 443}:
        signals.append(UrlSignal("unusual_port", "Unusual port", 10, f"URL explicitly uses port {parsed.port}"))

    if hostname.startswith("xn--") or ".xn--" in hostname:
        signals.append(UrlSignal("punycode", "Punycode hostname", 22, "Hostname uses internationalized-domain punycode"))

    if _looks_like_ip(hostname):
        signals.append(UrlSignal("ip_hostname", "IP address hostname", 20, "URL uses a raw IP address instead of a domain name"))

    labels = hostname.split(".")
    tld = labels[-1] if labels else ""
    if tld in SUSPICIOUS_TLDS:
        signals.append(UrlSignal("suspicious_tld", "Higher-risk TLD", 12, f".{tld} is frequently abused in disposable/phishing infrastructure"))

    hyphen_count = hostname.count("-")
    if hyphen_count >= 3:
        signals.append(UrlSignal("many_hyphens", "Many hostname hyphens", 8, f"Hostname contains {hyphen_count} hyphens"))

    if len(hostname) >= 45:
        signals.append(UrlSignal("long_hostname", "Long hostname", 8, f"Hostname is {len(hostname)} characters long"))

    if _hostname_entropy(hostname) >= 4.15 and len(hostname) >= 20:
        signals.append(UrlSignal("high_entropy", "High-entropy hostname", 10, "Hostname character distribution looks unusually random"))

    compact = re.sub(r"[^a-z0-9]", "", hostname)
    for brand, aliases in MALAYSIAN_BRANDS.items():
        mentions_brand = any(alias in compact for alias in aliases)
        if mentions_brand:
            official = any(hostname == d or hostname.endswith("." + d) for d in OFFICIAL_DOMAINS[brand])
            if not official:
                signals.append(UrlSignal(
                    "brand_impersonation",
                    "Possible brand impersonation",
                    35,
                    f"Hostname references {brand} but is not in ShieldScan's official-domain allowlist",
                ))
                break

    suspicious_path_terms = ["verify", "secure", "login", "update", "account", "wallet", "claim", "reward"]
    path_and_query = (parsed.path + "?" + parsed.query).lower()
    matched = [term for term in suspicious_path_terms if term in path_and_query]
    if len(matched) >= 2:
        signals.append(UrlSignal(
            "credential_bait_path",
            "Credential-bait path",
            12,
            "URL path/query contains multiple account-verification terms: " + ", ".join(matched[:4]),
        ))

    return signals


def url_signal_score(signals: List[UrlSignal]) -> int:
    """Combine deterministic URL signals into a capped 0-100 score."""
    return min(100, sum(max(0, signal.weight) for signal in signals))
