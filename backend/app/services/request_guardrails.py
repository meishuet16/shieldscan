from __future__ import annotations

import os
import time
from collections import defaultdict, deque
from threading import Lock
from typing import Deque

MAX_REQUEST_BYTES = int(os.getenv("SHIELDSCAN_MAX_REQUEST_BYTES", str(2 * 1024 * 1024)))
RATE_LIMIT_REQUESTS = int(os.getenv("SHIELDSCAN_RATE_LIMIT_REQUESTS", "20"))
RATE_LIMIT_WINDOW_SECONDS = int(os.getenv("SHIELDSCAN_RATE_LIMIT_WINDOW_SECONDS", "60"))

_BUCKETS: dict[str, Deque[float]] = defaultdict(deque)
_LOCK = Lock()


def request_too_large(content_length: str | None) -> bool:
    if not content_length:
        return False
    try:
        return int(content_length) > MAX_REQUEST_BYTES
    except ValueError:
        return True


def allow_request(client_key: str, now: float | None = None) -> tuple[bool, int]:
    """Simple in-process sliding-window limiter.

    This is intentionally dependency-free and suitable as a first protection layer for a
    single-process deployment. Multi-instance production deployments should replace it
    with a shared store such as Redis/Upstash so limits are consistent across replicas.
    """
    timestamp = time.monotonic() if now is None else now
    cutoff = timestamp - RATE_LIMIT_WINDOW_SECONDS

    with _LOCK:
        bucket = _BUCKETS[client_key]
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()

        if len(bucket) >= RATE_LIMIT_REQUESTS:
            retry_after = max(1, int(RATE_LIMIT_WINDOW_SECONDS - (timestamp - bucket[0])))
            return False, retry_after

        bucket.append(timestamp)
        return True, 0


def reset_rate_limits() -> None:
    with _LOCK:
        _BUCKETS.clear()
