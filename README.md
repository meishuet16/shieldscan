# 🛡️ ShieldScan AI

### **Malaysia-focused fraud intelligence for suspicious links, messages, and screenshots**

> **“Is this a scam?” should not be answered by one AI guess.**

ShieldScan helps users inspect suspicious digital content before they click, pay, reply, or share personal information. It combines **Gemini semantic analysis**, **deterministic security signals**, **safe network metadata**, and **sourced Malaysian threat intelligence** into one explainable risk report.

It started as a **Project 2030: MyAI Future Hackathon** prototype by **MyviVroomVroom**. The current system goes beyond the original demo: AI helps understand the content, while explicit evidence, retrieval and scoring logic make the result easier to inspect and challenge.

---

## 🔗 Try it / project links

| Link | Destination |
| --- | --- |
| 🌐 **Live Web App** | [shieldscan-frontend.onrender.com](https://shieldscan-frontend.onrender.com/) |
| ⚡ **Backend API** | [shieldscan-backend-esbt.onrender.com](https://shieldscan-backend-esbt.onrender.com/) |
| 💚 **Backend Health** | [shieldscan-backend-esbt.onrender.com/api/health](https://shieldscan-backend-esbt.onrender.com/api/health) |
| 📺 **5-Minute Pitch Video** | [YouTube](https://youtu.be/ghL32WbbNEw) |
| 📊 **Pitch Deck** | [Google Slides](https://docs.google.com/presentation/d/1Jbwn01U6QiXHhrnqZCxwgVfeUZSHYf_P3s38hspAJmQ/edit?usp=sharing) |

> ℹ️ `shieldscan-frontend.onrender.com` is the known public frontend deployment. The repository also contains `frontend/vercel.json` for Flutter Web deployment on Vercel, but a production `*.vercel.app` domain is not currently recorded in the repo. A deployment URL being live does not by itself prove it is serving the latest `main` commit, so deployment freshness should be verified separately.

---

## 🎯 Problem statement

Scam checking is messy for an ordinary user because suspicious content does not arrive in one neat format. It may be a banking URL, WhatsApp message, SMS, email, fake notice or screenshot.

The user then has to answer several different questions at once:

- Does this link imitate a Malaysian bank or trusted brand?
- Is the domain technically suspicious or unusually new?
- Does the wording resemble phishing, impersonation, investment or credential-stealing tactics?
- Has a similar pattern appeared in Malaysian fraud guidance?
- Is HTTPS meaningful evidence here, or does the suspicious site simply have a valid certificate?
- Most importantly: **what should I do next?**

A plain LLM can understand language and screenshots, but it can also hallucinate evidence or sound too confident. A simple URL checker has the opposite problem: it can inspect technical details while missing the meaning and social-engineering context.

### The idea behind ShieldScan

Instead of asking one model to decide everything, ShieldScan separates the job:

**understand the content → collect verifiable signals → retrieve relevant intelligence → assemble a bounded risk score → explain the result**.

---

## 💡 Solution

ShieldScan accepts three input types:

| Input | Example | What ShieldScan inspects |
| --- | --- | --- |
| 🔗 **URL** | Suspicious banking/login link | URL structure, brand lookalikes, DNS, TLS, domain registration metadata, semantic context |
| 💬 **Text** | SMS / WhatsApp / email copy | Scam language, social-engineering patterns, semantic indicators, related threat intelligence |
| 🖼️ **Screenshot** | Scam chat, fake notice, payment request | Multimodal semantic analysis, fraud indicators and semantic threat-intel retrieval |

The output is more than a red/green badge. A result can include:

- **risk level + risk score**;
- the evidence that affected the score;
- Gemini-detected semantic fraud indicators;
- related Malaysian threat intelligence with provenance;
- English and Bahasa Malaysia explanations;
- practical next-step recommendations.

> 🧠 **Gemini helps ShieldScan understand. The risk engine controls how evidence affects the score. Threat-intelligence retrieval helps ground the explanation.**

---

## 👤 User flow

```text
1. Open ShieldScan
        ↓
2. Choose URL / Text / Screenshot
        ↓
3. Paste or upload suspicious content
        ↓
4. ShieldScan analyses it
        ↓
   Gemini semantic understanding
        ↓
   URL + network evidence (for URLs)
        ↓
   Malaysian threat-intelligence retrieval
        ↓
   Grounded report generation
        ↓
5. Receive one explainable result
        ↓
   Risk level + score
   Why it was flagged
   Technical evidence
   Related official intelligence
   Recommended action
        ↓
6. Verify before clicking, paying,
   replying or sharing sensitive information
```

In human terms: **submit suspicious thing → see why it looks risky → know what to do next**. You should not need to become a cybersecurity analyst first. 😭

---

## ⚙️ How it works

```text
┌───────────────────────────────┐
│ URL / Text / Screenshot       │
└──────────────┬────────────────┘
               ↓
┌───────────────────────────────┐
│ Gemini semantic analysis      │
│ meaning • intent • indicators │
└──────────────┬────────────────┘
               ↓
┌───────────────────────────────┐
│ Evidence-based risk engine    │
│ URL signals + DNS/TLS/RDAP    │
└──────────────┬────────────────┘
               ↓
┌───────────────────────────────┐
│ Threat-intelligence retrieval │
│ LanceDB → filters → fallback  │
└──────────────┬────────────────┘
               ↓
┌───────────────────────────────┐
│ Grounded Gemini synthesis     │
│ evidence + explanation        │
└──────────────┬────────────────┘
               ↓
┌───────────────────────────────┐
│ Explainable bilingual report  │
└───────────────────────────────┘
```

### 🧠 1. Semantic & multimodal analysis

Gemini interprets what the content is trying to communicate: urgency, impersonation language, payment instructions, credential requests and screenshot context.

For screenshots, raw base64 is **not** used as a retrieval query. ShieldScan first derives a bounded semantic query from the model summary and indicators, then searches threat intelligence with that text.

### 🔍 2. Deterministic URL intelligence

URL scans can check explainable signals such as HTTPS usage, raw-IP hosts, punycode, suspicious TLDs, unusual ports, hostname shape/entropy, Malaysian-brand lookalikes and credential-bait paths.

These become typed evidence objects instead of disappearing inside an AI prompt.

### 🌐 3. Safe network intelligence

For URL scans ShieldScan can collect bounded infrastructure metadata from:

- **DNS** resolution and public/non-public address classification;
- **TLS** certificate validation against a validated public IP while preserving the hostname for SNI;
- **RDAP** registration metadata and domain-age signals when available.

ShieldScan deliberately does **not** fetch the submitted webpage, execute its JavaScript, follow arbitrary page redirects or submit forms. We are building a scam checker, not making the backend click scam links for fun. 🤡

Also: **HTTPS ≠ safe**. A scam site can have a perfectly valid TLS certificate.

### 🇲🇾 4. Malaysian threat intelligence

The versioned corpus contains provenance-bearing records based on official/public material from sources such as **Bank Negara Malaysia (BNM)**, **Polis Diraja Malaysia (PDRM)** and **Malaysian Communications and Multimedia Commission (MCMC)**.

Default retrieval path:

```text
LanceDB semantic search
        ↓
threat-pattern role filter
        ↓
similarity threshold
        ↓
local sourced keyword fallback
```

Evidence roles keep different information from being mixed together:

| Evidence role | Purpose |
| --- | --- |
| `threat_pattern` | Supports matching against known scam patterns |
| `response_guidance` | Victim-response / reporting advice only |
| `context_only` | Background context |

A retrieved match is **related intelligence, not proof** that the submitted item is fraudulent.

### 🧮 5. Risk scoring

| Risk score | Level | Meaning |
| ---: | --- | --- |
| 0–19 | 🟢 SAFE | Few current risk signals |
| 20–39 | 🔵 LOW | Some caution warranted |
| 40–64 | 🟡 MEDIUM | Multiple or meaningful warning signs |
| 65–84 | 🟠 HIGH | Strong suspicious signals |
| 85–100 | 🔴 CRITICAL | Very strong combined risk signals |

These are **engineering thresholds, not calibrated fraud probabilities**.

The API separates:

- `risk_score` — final ShieldScan risk score;
- `ai_confidence_score` — Gemini's self-reported confidence;
- `deterministic_score` — deterministic evidence contribution;
- `risk_evidence` — typed URL/network evidence;
- `threat_intel_matches` — sourced related intelligence;
- `scoring_version` — scoring-policy version.

Legacy `confidence_score` and `rag_matches` remain temporarily for compatibility. See [`docs/API_COMPATIBILITY.md`](docs/API_COMPATIBILITY.md).

---

## 🏗️ Architecture & tech stack

| Layer | Technology | Job |
| --- | --- | --- |
| 🎨 Frontend | Flutter Web | Scan UI, SSE progress, explainable results |
| ⚡ Backend | FastAPI + Python | API, orchestration, risk engine, security controls |
| 🧠 AI | Gemini via Google Gen AI SDK | Semantic/multimodal understanding + grounded synthesis |
| 🔎 Retrieval | LanceDB + multilingual sentence-transformer | Local semantic threat-intelligence search |
| ☁️ Optional retrieval | Vertex AI Search | Managed retrieval alternative |
| 🇲🇾 Corpus | Versioned JSON + controlled ingestion scripts | Malaysian fraud intelligence with provenance |
| 🌐 Network intel | DNS + TLS + RDAP | Bounded URL infrastructure evidence |
| 🚀 Web hosting | Render public demo + Vercel config | Flutter Web deployment options |
| 🐍 Backend hosting | Render | FastAPI service + LanceDB index build |
| ✅ CI | GitHub Actions | Backend tests + Flutter analysis/tests |

---

## 🚀 Deployment

### Known public deployment

```text
User
  │
  ↓
Render-hosted Flutter Web
shieldscan-frontend.onrender.com
  │
  │ API / SSE
  ↓
Render FastAPI backend
shieldscan-backend-esbt.onrender.com
  ├─ Gemini API
  ├─ LanceDB local index
  ├─ DNS / TLS metadata
  └─ fixed RDAP provider
```

The public Render frontend is the deployment URL currently recorded for the project. **Whether it is serving the newest `main` commit should be verified from the deployment platform rather than inferred from the URL alone.**

### Vercel frontend configuration

The repo also includes [`frontend/vercel.json`](frontend/vercel.json). It builds Flutter Web from the stable Flutter channel and injects the backend through `API_BASE_URL`.

```text
frontend/
  ↓
flutter pub get
  ↓
flutter build web --release
  ↓
Vercel serves build/web
```

A specific production `*.vercel.app` domain is not currently recorded in the repository.

### Render backend

[`render.yaml`](render.yaml) configures the Python backend. Deployment installs the RAG dependencies and builds the semantic index:

```bash
pip install -r requirements-rag.txt
python scripts/build_threat_index.py
```

Then starts FastAPI:

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

So production RAG does **not** require somebody to manually clone the repo on a laptop and build LanceDB first. The index is built where the backend deploys from the versioned corpus.

`GEMINI_API_KEY` must be configured as a deployment secret and must not be committed to the repository.

---

## 🔌 API

### `POST /api/scan`
Returns a complete JSON result.

### `POST /api/scan/stream`
Streams analysis stages and the final result through **Server-Sent Events (SSE)** for visible frontend progress.

### `GET /api/health`
Backend health/configuration endpoint.

When the backend is running, FastAPI interactive documentation is available at `/docs`.

---

## 🔐 Safety, privacy & abuse controls

Current controls include request-size limits, in-process rate limiting, request IDs, response-latency metadata, metadata-only operational logging, SSRF-aware public-address validation, direct-IP TLS validation after address checks and no arbitrary submitted-page fetching.

Submitted URLs/text/images are not intentionally stored in a scan-history database by the current service. Network/retrieval failures also **never become SAFE evidence**.

More detail:

- [`docs/SECURITY_MODEL.md`](docs/SECURITY_MODEL.md)
- [`docs/PRIVACY_AND_RETENTION.md`](docs/PRIVACY_AND_RETENTION.md)

---

## 🧪 Testing & evaluation

Backend and frontend have separate GitHub Actions CI workflows. Regression coverage includes official banking URLs, lookalike domains, credential bait, benign banking discussion, threat-intel positives, response-guidance separation, screenshot retrieval-query construction, DNS/TLS/RDAP behaviour and API compatibility.

Gemini wording is not treated like deterministic code in ordinary CI because generated output can vary between model revisions and runs.

See [`docs/EVALUATION.md`](docs/EVALUATION.md).

---

## 🧰 Run locally

### Backend

```bash
git clone https://github.com/meishuet16/shieldscan.git
cd shieldscan/backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements-rag.txt
```

Set `GEMINI_API_KEY`, then:

```bash
python scripts/build_threat_index.py
uvicorn main:app --reload --port 8080
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

---

## 🗂️ Threat-intelligence maintenance

```text
Official BNM / PDRM / MCMC source
        ↓
source-specific ingestion script
        ↓
review provenance + corpus diff
        ↓
run tests / evaluation
        ↓
rebuild LanceDB index
        ↓
deploy
```

The corpus is deliberately controlled instead of silently scraping arbitrary internet pages during each scan.

---

## 🚧 Current limitations

- risk thresholds/network weights are not statistically calibrated yet;
- the Malaysian corpus is useful but not exhaustive;
- screenshot quality still needs a larger labelled evaluation set;
- RDAP data can be incomplete/provider-dependent;
- arbitrary webpage content and redirect chains are not inspected;
- there is no commercial malware/domain-reputation feed yet;
- the current rate limiter is in-process rather than shared across multiple instances;
- deployed end-to-end behaviour still needs verification after significant releases.

So no, ShieldScan is not claiming to be a magical **100% scam detector™**. It is an explainable decision-support system that tries to show the user *why* something looks risky.

---

## 🛣️ Roadmap

Next production-oriented work focuses on:

1. larger labelled URL/text/screenshot evaluation sets and measured precision/recall;
2. shared rate-limit state for multi-instance deployments;
3. optional commercial reputation intelligence without unsafe arbitrary-page fetching;
4. representative deployed end-to-end verification.

See [`docs/PRODUCTION_ROADMAP.md`](docs/PRODUCTION_ROADMAP.md).

---

## 🏁 Project origin

ShieldScan was originally created by **MyviVroomVroom** for **Project 2030: MyAI Future Hackathon — Track 5: Secure Digital**.

The original prototype proved the interaction idea: make suspicious-content checking easier for Malaysian users. The current version keeps that simple user flow while rebuilding the internals around **evidence, provenance, safer networking, evaluation and clearer system boundaries**.

---

## ⚠️ Responsible use

ShieldScan is a **decision-support tool**, not a guarantee that something is safe or fraudulent. Verify suspicious financial requests through the institution's official channels and use current Malaysian reporting/response channels when a scam is suspected.

**Think before you click. Verify before you pay. 🛡️**
