# 🛡️ ShieldScan AI

### Evidence-based Malaysian fraud analysis for URLs, messages, and screenshots

ShieldScan began as a Project 2030 hackathon prototype and is being upgraded into a more auditable fraud-analysis and verification platform. Gemini is still part of the system, but it is no longer treated as the sole source of truth.

## What ShieldScan does

Users can submit:

- a suspicious URL;
- a text message;
- a screenshot/image.

ShieldScan combines semantic analysis, deterministic evidence, Malaysian threat intelligence, and grounded report generation to produce an English/Bahasa Malaysia risk report.

## Current analysis pipeline

```text
input
  ↓
Gemini semantic / multimodal analysis
  ↓
Deterministic risk engine
  ├─ lexical URL signals
  └─ bounded DNS / TLS / RDAP metadata for URL scans
  ↓
Threat-intelligence retrieval
  ├─ LanceDB semantic retrieval
  ├─ evidence-role filtering
  ├─ similarity threshold
  └─ local keyword fallback
  ↓
Grounded Gemini synthesis
  ↓
final report
```

Gemini can improve semantic interpretation, bilingual summaries, indicators, and recommendations. It cannot overwrite the final authoritative risk score, threat level, or deterministic evidence assembled by the risk engine.

## URL intelligence

URL scans currently inspect deterministic signals such as:

- HTTPS usage;
- raw-IP hostnames;
- punycode;
- suspicious TLDs;
- unusual ports;
- hostname entropy/shape;
- Malaysian-brand lookalikes;
- credential-bait paths.

They can also use bounded network metadata:

- DNS resolution and public/non-public address classification;
- TLS certificate validation against a previously validated public IP using the original hostname for SNI;
- RDAP registration-date metadata queried through a fixed provider endpoint.

ShieldScan does **not** fetch the submitted webpage, execute its JavaScript, follow its redirects, or submit forms/credentials.

A valid TLS certificate or public DNS result is **not** treated as proof that a site is safe. Scam sites can also use HTTPS and normal public hosting.

## Threat-intelligence retrieval

The versioned corpus contains provenance-bearing Malaysian fraud intelligence sourced from official/public BNM, PDRM, and MCMC material.

The default retrieval path is:

```text
LanceDB semantic retrieval
→ threat-pattern role filtering
→ similarity threshold
→ local sourced keyword fallback
```

Important distinction:

- `threat_pattern` records can support scam-pattern matching;
- `response_guidance` records are for victim-response advice and are excluded from fraud-pattern retrieval;
- `context_only` records are background material.

Retrieved records are supporting evidence, not proof that the scanned item is fraudulent.

## Image / screenshot analysis

Image scans use Gemini for multimodal interpretation. ShieldScan then builds a bounded text-only retrieval query from the semantic summaries and fraud indicators.

Raw image bytes/base64 are never sent into LanceDB, Vertex AI Search, or local keyword retrieval.

## Risk scoring

Current score bands:

| Risk score | Level |
| ---: | --- |
| 0–19 | SAFE |
| 20–39 | LOW |
| 40–64 | MEDIUM |
| 65–84 | HIGH |
| 85–100 | CRITICAL |

These bands are engineering defaults, **not calibrated fraud probabilities**.

The response separates:

- final risk score;
- Gemini self-reported confidence;
- deterministic score;
- typed deterministic evidence;
- scoring version;
- sourced threat-intelligence matches.

See `docs/EVALUATION.md` for the current regression suite and calibration limitations.

## Safety, privacy, and abuse controls

Current backend controls include:

- request-body size limits on scan endpoints;
- per-client in-process sliding-window rate limiting;
- request IDs and response-latency metadata;
- operational logging without intentionally logging submitted URL/text/image content;
- no scan-history database in the current service;
- SSRF-aware public-address checks before user-derived hosts are used for DNS/TLS metadata work.

The current rate limiter is per application instance. Multi-instance deployments need shared state such as Redis/Upstash.

See `docs/SECURITY_MODEL.md` and `docs/PRIVACY_AND_RETENTION.md`.

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter Web |
| Backend | FastAPI / Python |
| Semantic + multimodal reasoning | Gemini via Google Gen AI SDK |
| Default semantic retrieval | LanceDB + multilingual sentence-transformer embeddings |
| Optional managed retrieval | Vertex AI Search |
| Threat-intel corpus | Versioned JSON + official-source ingestion scripts |
| Deployment configuration | Vercel frontend + Render backend |

Gemini remains an important reasoning layer, but ShieldScan is deliberately designed so that an LLM answer alone does not determine the final URL risk verdict.

## Local development

### Backend

```bash
git clone https://github.com/meishuet16/shieldscan.git
cd shieldscan/backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements-rag.txt
```

Set `GEMINI_API_KEY`, then build the local threat-intelligence index:

```bash
python scripts/build_threat_index.py
uvicorn main:app --reload --port 8080
```

Useful optional environment variables:

```text
SHIELDSCAN_RETRIEVAL_PROVIDER=lancedb
SHIELDSCAN_SEMANTIC_MIN_SIMILARITY=0.35
SHIELDSCAN_LOCAL_KEYWORD_MIN_SCORE=0.20
SHIELDSCAN_LANCEDB_PATH=data/lancedb
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## API

### `POST /api/scan`

Returns a complete JSON scan result.

### `POST /api/scan/stream`

Streams progress and the final result through Server-Sent Events.

### `GET /api/health`

Returns backend health/configuration status.

Interactive FastAPI docs are available at `/docs` while the backend is running.

## Threat-intelligence maintenance

The repository includes controlled ingestion scripts for official sources such as BNM, PDRM, and MCMC.

Corpus refreshes should be reviewed before indexing/deployment:

```text
run source-specific ingestion
→ review corpus/provenance diff
→ run tests/evaluation fixtures
→ rebuild LanceDB index
→ deploy
```

A retrieval failure never becomes a SAFE signal.

## CI and evaluation

The repository includes Backend CI and Frontend CI. Deterministic regression fixtures cover cases such as:

- official Malaysian banking URLs;
- banking lookalike domains;
- IP-host credential bait;
- phishing/investment retrieval positives;
- benign banking discussions that must not create threat matches;
- response guidance that must not be mistaken for fraud evidence;
- image retrieval-query construction and base64 exclusion.

Gemini outputs are not asserted in ordinary CI because generative responses can vary between model revisions and runs. Generative quality should be measured separately with labelled offline evaluation data.

## Known limitations

- Current thresholds and network-signal weights are not statistically calibrated.
- The local threat-intelligence corpus is intentionally limited and not an exhaustive official database.
- RDAP metadata can be missing or provider-dependent.
- ShieldScan does not currently inspect webpage content or redirect chains.
- It does not use a commercial malware/domain-reputation feed yet.
- Image semantic/retrieval quality still needs a labelled screenshot evaluation set.
- Current rate limiting is not shared across multiple backend instances.

These limitations are intentional to document rather than hide.

## Project origin

ShieldScan was originally built by **MyviVroomVroom** for **Project 2030: MyAI Future Hackathon**, Track 5 — Secure Digital. The current upgrade branch extends that prototype with evidence-based scoring, grounded threat intelligence, security controls, evaluation fixtures, and production-oriented architecture work.

## Responsible use

ShieldScan is a decision-support tool, not a guarantee that content is safe or fraudulent. For suspected financial scams, verify through the relevant institution's official channels and use current Malaysian reporting/response channels.
