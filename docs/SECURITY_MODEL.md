# ShieldScan Security Model

ShieldScan analyses potentially malicious content. The scanner itself is therefore security-sensitive infrastructure, not a normal content form.

## Trust boundaries

1. **User input is untrusted** — URL strings, text, and image payloads can be hostile or malformed.
2. **LLM output is untrusted** — model-generated JSON is parsed and validated; model confidence is not treated as probability.
3. **External intelligence is untrusted until normalized** — DNS, TLS, RDAP, reputation, and search-provider results must become typed evidence before affecting the result.
4. **Outbound network access is privileged** — ShieldScan must not fetch arbitrary user-submitted webpages.

## Current URL-analysis policy

The current URL pipeline combines lexical/domain-shape analysis with bounded network metadata.

Lexical signals include protocol use, raw-IP hosts, punycode, suspicious TLDs, unusual ports, hostname entropy, brand impersonation, and credential-bait paths.

Network metadata currently includes:

- DNS resolution and public/non-public target classification;
- TLS certificate validation by connecting directly to a previously validated public IP while preserving hostname/SNI verification;
- RDAP registration-date metadata queried through a fixed provider endpoint.

ShieldScan still does **not** request the submitted webpage, execute its JavaScript, follow its redirects, or submit credentials/forms.

## Outbound network policy

For user-derived hosts, ShieldScan must:

- parse and canonicalize the hostname;
- never use the submitted URL as an outbound HTTP destination;
- resolve DNS and reject loopback, private, link-local, multicast, reserved, or unspecified addresses;
- reject mixed public/private DNS answers;
- connect TLS only to a validated public IP while using the original hostname for SNI/certificate checks;
- apply strict connect/read timeouts;
- never forward internal credentials, cloud metadata headers, cookies, or ambient authorization;
- prefer fixed provider APIs (for example RDAP/reputation) over arbitrary page fetching.

`app/services/network_safety.py` contains address-classification policy primitives. `app/services/network_intelligence.py` implements the current DNS/TLS/RDAP metadata layer.

## Network evidence semantics

Network evidence is supplementary, not a verdict. Positive metadata such as a valid TLS certificate or public DNS carries **zero negative-risk weight** because scam sites can also use HTTPS and normal hosting.

Risk-bearing network signals are bounded to at most 25 additional deterministic points per scan. Provider failures or unavailable metadata never become a SAFE signal.

A recently registered domain may contribute risk context, but domain age alone is not proof of fraud.

## Risk-score semantics

`confidence_score` in the public response is the ShieldScan **risk score**, not an LLM probability.

The response also exposes:

- `ai_confidence_score`: semantic-model self-reported confidence, retained only as a supporting signal;
- `deterministic_score`: deterministic lexical/network contribution;
- `risk_evidence`: typed evidence explaining contributions;
- `scoring_version`: version identifier for reproducibility.

Current score bands and provider weights remain engineering defaults until calibrated against a larger labelled evaluation set.

## Threat-intelligence provenance

The default retrieval path uses a provenance-bearing corpus, LanceDB semantic retrieval, evidence-role filtering, similarity thresholds, and grounded report synthesis. Local keyword fallback also applies a minimum evidence threshold to reduce generic-word false positives.

Retrieved material is supporting evidence, not proof that the scanned item is malicious. `response_guidance` records are excluded from fraud-pattern retrieval.

## Abuse and privacy controls

The scan endpoints apply request-size limits and per-client in-process rate limiting. Responses include request IDs and latency metadata. Application logs record operational metadata only; submitted URL/text/image content is not intentionally logged.

The current service does not maintain a scan-history database. See `docs/PRIVACY_AND_RETENTION.md` for the retention policy and future requirements.

## Known limitations

- RDAP registration dates can be absent or provider-dependent and are not yet calibrated as fraud indicators.
- DNS/TLS/RDAP checks do not provide commercial domain reputation or known-malware verdicts.
- No redirect-chain or webpage-content analysis is performed because arbitrary page fetching remains disabled.
- In-process rate limiting is per application instance; multi-instance deployments require shared state such as Redis.
- No calibrated probability or validated accuracy metric yet.
- Image-to-intelligence retrieval is not implemented; image scans currently rely on semantic analysis only.
- The threat-intelligence corpus is not exhaustive.

These limitations are product requirements, not claims to hide in marketing language.
