import ipaddress
import socket
from dataclasses import dataclass
from typing import Iterable, List


@dataclass(frozen=True)
class ResolvedAddress:
    host: str
    ip: str
    is_public: bool
    reason: str | None = None


def _is_public_ip(value: str) -> bool:
    ip = ipaddress.ip_address(value)
    return not (
        ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_multicast
        or ip.is_reserved
        or ip.is_unspecified
    )


def classify_addresses(host: str, addresses: Iterable[str]) -> List[ResolvedAddress]:
    results: List[ResolvedAddress] = []
    for value in addresses:
        try:
            public = _is_public_ip(value)
            reason = None if public else "non-public address blocked by outbound fetch policy"
        except ValueError:
            public = False
            reason = "invalid IP address"
        results.append(ResolvedAddress(host=host, ip=value, is_public=public, reason=reason))
    return results


def resolve_public_addresses(host: str) -> List[ResolvedAddress]:
    """Resolve a hostname and classify every returned address.

    This function does not perform any HTTP request. Callers that later add outbound
    reputation/TLS providers must reject a target if *any* resolution is non-public,
    then re-resolve immediately before connection to reduce DNS rebinding risk.
    """
    infos = socket.getaddrinfo(host, None, proto=socket.IPPROTO_TCP)
    addresses = sorted({item[4][0] for item in infos})
    return classify_addresses(host, addresses)


def assert_safe_public_target(host: str, addresses: Iterable[str]) -> List[ResolvedAddress]:
    classified = classify_addresses(host, addresses)
    if not classified:
        raise ValueError("hostname resolved to no addresses")

    blocked = [item for item in classified if not item.is_public]
    if blocked:
        details = ", ".join(item.ip for item in blocked)
        raise ValueError(f"outbound target rejected: {details}")

    return classified
