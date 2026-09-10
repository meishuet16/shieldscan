# ShieldScan Security Model

ShieldScan analyses potentially malicious content. That means the scanner itself must be treated as a security-sensitive service, not as a normal content form.

## Trust boundaries

1. **User input is untrusted** — URL strings, text, and uploaded image payloads can be hostile or malformed.
2. **LLM output is untrusted** — model-generated JSON is parsed and validated; model confidence is not treated as probability.
3. **External intelligence is untrusted until normalized** — future DNS, TLS, WHOIS/RDAP, reputation, and search providers must be converted into typed evidence.
4. **Outbound network access is privileged** — arbitrary user-supplied URLs must never be fetched without SSRF controls.

## Current URL-analysis policy

The v2 pipeline performs lexical URL analysis without fetching the target. Signals include protocol use, raw-IP hosts, punycode, suspicious TLDs, unusual ports, hostname entropy, brand impersonation, and credential-bait paths.

This creates useful evidence while keeping the first production upgrade safe from SSRF.

## Outbound provider policy

Before any future component connects to a user-derived host:

- parse and canonicalize the hostname;
- reject credentials embedded in the authority component;
- resolve DNS;
- reject loopback, private, link-local, multicast, reserved, or unspecified addresses;
- reject mixed public/private DNS answers;
- re-resolve immediately before connection to reduce DNS-rebinding risk;
- apply strict connect/read timeouts;
- cap redirect count and repeat validation for every redirect target;
- cap response size and accepted MIME types;
- never forward internal credentials, cloud metadata headers, or ambient authorization;
- prefer provider APIs (reputation/RDAP/DNS) over arbitrary page fetching when possible.

`app/services/network_safety.py` contains the first reusable policy primitives for this boundary.

## Risk-score semantics

`confidence_score` in the public response is now the ShieldScan **risk score**, not an LLM probability.

The response also exposes:

- `ai_confidence_score`: the semantic model's self-reported confidence, retained only as a supporting signal;
- `deterministic_score`: score contributed by deterministic checks;
- `risk_evidence`: typed evidence explaining deterministic contributions;
- `scoring_version`: version identifier for reproducibility.

The current scoring policy is intentionally simple and must be calibrated against an evaluation dataset before any claim of measured accuracy is made.

## Threat-intelligence provenance

The local seed corpus uses transparent keyword retrieval and returns structured provenance (`source_name`, `source_url`, matched terms, retrieval method). It is deliberately **not** described as RAG.

A future retrieval system should ingest official/public advisories, preserve source URL and publication metadata, support hybrid lexical/vector search, deduplicate records, and evaluate retrieval quality separately from final scam classification.

## Known limitations

- No live domain reputation, RDAP/WHOIS, DNS-age, TLS-certificate, or redirect-chain checks yet.
- No calibrated probability or validated accuracy metric yet.
- Image-to-intelligence retrieval is not implemented; image scans currently rely on semantic analysis only.
- No persistence, abuse controls, user authentication, rate limiting, or scan-history privacy policy yet.
- The local threat-intelligence corpus is intentionally small and should not be interpreted as an exhaustive official database.

These limitations are product requirements, not items to hide behind marketing language.
