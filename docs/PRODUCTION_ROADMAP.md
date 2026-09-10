# ShieldScan Production Roadmap

ShieldScan is being evolved from a hackathon MVP into an evidence-based Malaysian fraud intelligence and verification platform.

## Phase 1 — Auditable core (in progress)

- Deterministic URL lexical intelligence
- Versioned risk engine
- Separate AI confidence from final risk score
- Structured risk evidence
- Provenance-bearing local threat-intelligence retrieval
- SSRF-safe outbound target policy primitives
- Backend unit tests and pull-request CI

## Phase 2 — Safe network intelligence

Introduce provider interfaces instead of hard-wiring external services into scan routes.

Planned evidence sources:

- DNS resolution and hostname consistency
- TLS certificate metadata and expiry
- RDAP/domain registration age where available
- redirect-chain inspection behind strict SSRF controls
- domain/URL reputation provider adapters

Every provider must return typed evidence with provider name, observed value, timestamp, and failure state. Provider failures must degrade gracefully rather than silently becoming SAFE.

## Phase 3 — Real threat-intelligence retrieval

Replace the local seed corpus with an ingestion/indexing pipeline for public Malaysian scam advisories and verified threat-intelligence sources.

Requirements:

- source URL and publication date retained per record
- normalized scam category and entities
- deduplication and update tracking
- hybrid lexical/vector retrieval
- source citations returned to clients
- retrieval evaluation dataset (precision@k / recall-oriented checks)
- no claim of “official database access” unless an actual supported integration exists

## Phase 4 — Evaluation and calibration

Build labelled fixtures for legitimate and malicious URL/text/image inputs.

Measure at minimum:

- false-positive rate
- false-negative rate
- precision / recall / F1 by input type
- performance by scam category
- risk-score calibration / threshold behaviour
- regression across scoring versions

The product must not display model self-confidence as measured detection accuracy.

## Phase 5 — Product infrastructure

- PostgreSQL persistence for scan metadata and threat-intel records
- privacy-aware scan history
- rate limiting and abuse controls
- request size limits and image validation
- structured logging and trace/request IDs
- operational metrics and health/readiness endpoints
- retention policy for submitted content
- optional anonymous/public reporting workflow with moderation and deduplication

## Phase 6 — Evidence-first frontend

Redesign results around explanation rather than a dramatic percentage:

1. risk level
2. what ShieldScan observed
3. deterministic evidence
4. semantic indicators
5. related sourced advisories
6. safe next actions / official verification channels
7. explicit uncertainty and unavailable checks

The UI should distinguish **observed**, **inferred**, and **not checked** states.

## Definition of “production-grade” for this repository

ShieldScan should be considered production-ready only when:

- CI is green and meaningful integration/security tests exist;
- high-risk outbound networking is constrained by tested SSRF protections;
- evidence providers fail safely and visibly;
- risk thresholds are backed by evaluation data;
- threat-intelligence provenance is preserved end-to-end;
- privacy, retention, abuse, and operational behaviour are documented;
- README claims match implemented behaviour.
