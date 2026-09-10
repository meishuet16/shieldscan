from __future__ import annotations

import os
import socket
import ssl
from dataclasses import dataclass
from datetime import datetime, timezone
from urllib.parse import quote, urlparse

import httpx

from app.services.network_safety import resolve_public_addresses


RDAP_BASE_URL = os.getenv("SHIELDSCAN_RDAP_BASE_URL", "https://rdap.org/domain/")
NETWORK_TIMEOUT_SECONDS = float(os.getenv("SHIELDSCAN_NETWORK_TIMEOUT_SECONDS", "3.0"))


@dataclass(frozen=True)
class NetworkIntelSignal:
    code: str
    label: str
    weight: int
    evidence: str


def _hostname_from_url(url: str) -> str | None:
    try:
        parsed = urlparse(url if "://" in url else f"https://{url}")
        return (parsed.hostname or "").strip(".").lower() or None
    except ValueError:
        return None


def _tls_signal(host: str, ip: str) -> list[NetworkIntelSignal]:
    context = ssl.create_default_context()
    raw = socket.create_connection((ip, 443), timeout=NETWORK_TIMEOUT_SECONDS)
    try:
        with context.wrap_socket(raw, server_hostname=host) as tls:
            cert = tls.getpeercert()
            not_after = cert.get("notAfter")
            cipher = tls.cipher()
            details = [f"TLS validated via {ip}"]
            if not_after:
                details.append(f"certificate expires {not_after}")
            if cipher:
                details.append(f"cipher {cipher[0]}")
            return [
                NetworkIntelSignal(
                    code="tls_valid",
                    label="TLS certificate validated",
                    weight=0,
                    evidence="; ".join(details),
                )
            ]
    finally:
        try:
            raw.close()
        except OSError:
            pass


def _parse_rdap_created_at(payload: dict) -> datetime | None:
    for event in payload.get("events", []):
        action = str(event.get("eventAction", "")).lower()
        if action not in {"registration", "registered"}:
            continue
        raw = event.get("eventDate")
        if not raw:
            continue
        try:
            return datetime.fromisoformat(str(raw).replace("Z", "+00:00")).astimezone(timezone.utc)
        except ValueError:
            continue
    return None


def _rdap_signals(host: str) -> list[NetworkIntelSignal]:
    # The destination host is fixed by configuration; the user-controlled domain is
    # encoded only as a path component, so ShieldScan never follows a submitted URL.
    endpoint = f"{RDAP_BASE_URL.rstrip('/')}/{quote(host, safe='.-')}"
    with httpx.Client(timeout=NETWORK_TIMEOUT_SECONDS, follow_redirects=False) as client:
        response = client.get(endpoint, headers={"User-Agent": "ShieldScanNetworkIntel/1.0"})
        if response.status_code != 200:
            return []
        payload = response.json()

    created_at = _parse_rdap_created_at(payload)
    if not created_at:
        return []

    age_days = max(0, (datetime.now(timezone.utc) - created_at).days)
    weight = 20 if age_days <= 30 else 10 if age_days <= 90 else 0
    return [
        NetworkIntelSignal(
            code="domain_age",
            label="Domain registration age",
            weight=weight,
            evidence=f"RDAP registration date {created_at.date().isoformat()} ({age_days} days old)",
        )
    ]


def analyze_network_url(url: str) -> list[NetworkIntelSignal]:
    """Collect DNS, TLS and RDAP metadata without fetching the submitted webpage.

    DNS resolution is rejected if any answer is non-public. TLS connects directly to a
    previously validated public IP while preserving SNI/hostname certificate checks.
    RDAP queries a fixed provider endpoint and never follows the submitted URL.
    Provider failures are represented by absence of evidence, never a SAFE signal.
    """
    host = _hostname_from_url(url)
    if not host:
        return []

    signals: list[NetworkIntelSignal] = []
    try:
        resolved = resolve_public_addresses(host)
    except (OSError, socket.gaierror):
        return [
            NetworkIntelSignal(
                code="dns_unresolved",
                label="Hostname did not resolve",
                weight=12,
                evidence=f"DNS resolution failed for {host}",
            )
        ]

    if not resolved:
        return []

    blocked = [item.ip for item in resolved if not item.is_public]
    if blocked:
        return [
            NetworkIntelSignal(
                code="non_public_destination",
                label="Hostname resolves to a non-public network",
                weight=30,
                evidence=", ".join(blocked),
            )
        ]

    public_ips = [item.ip for item in resolved]
    signals.append(
        NetworkIntelSignal(
            code="dns_public",
            label="Public DNS resolution",
            weight=0,
            evidence=", ".join(public_ips[:4]),
        )
    )

    try:
        signals.extend(_tls_signal(host, public_ips[0]))
    except (OSError, ssl.SSLError, TimeoutError):
        signals.append(
            NetworkIntelSignal(
                code="tls_unverified",
                label="TLS certificate could not be validated",
                weight=8,
                evidence=f"TLS validation failed for {host}:443",
            )
        )

    try:
        signals.extend(_rdap_signals(host))
    except (httpx.HTTPError, ValueError, TypeError):
        pass

    return signals
