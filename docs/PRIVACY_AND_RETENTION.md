# Privacy and Retention

ShieldScan processes potentially sensitive scam reports, URLs, text and screenshots. The default service design therefore follows data minimisation.

## Current behaviour

- Scan request bodies are processed in memory and are not intentionally persisted by the application.
- Request logs contain metadata only: request ID, HTTP method, path, status code and latency.
- The application must not log submitted URLs, message text, screenshots, base64 payloads, extracted credentials, phone numbers or banking details.
- Threat-intelligence corpus data is public-source reference material and is versioned separately from user submissions.
- Request IDs are operational correlation identifiers only and must not encode personal data.

## Retention policy

The application currently has no database-backed user scan history. Therefore the intended application-level retention for submitted scan content is zero after request processing completes. Infrastructure providers may retain network/access logs according to their own platform policies; production deployment documentation should identify and minimise those logs where possible.

If scan history is added later, it must be opt-in or have an explicit product purpose, document a concrete retention period, support deletion, minimise stored content, and avoid storing raw screenshots or full message bodies unless strictly necessary.

## Abuse controls

The API applies configurable request-size and per-client rate limits before expensive scan processing. The current in-process limiter is a first deployment guardrail, not a distributed quota system. Multi-instance production deployment should move rate-limit state to a shared service such as Redis-compatible storage.

## Configuration

- `SHIELDSCAN_MAX_REQUEST_BYTES` — maximum request body size; default 2 MiB.
- `SHIELDSCAN_RATE_LIMIT_REQUESTS` — scan requests allowed per window; default 20.
- `SHIELDSCAN_RATE_LIMIT_WINDOW_SECONDS` — rate-limit window; default 60 seconds.
- `LOG_LEVEL` — server log level; default INFO.

## Future requirements

Before storing user submissions, add a documented lawful/product purpose, encryption-at-rest controls, deletion workflow, access controls, retention enforcement and a user-facing privacy notice. Do not silently turn operational logs into a scan-history database.
