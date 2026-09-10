# 🛡️ ShieldScan AI

### **Malaysia-focused fraud intelligence for suspicious links, messages, and screenshots**

> **“Is this a scam?” should not be answered by one AI guess.**

ShieldScan helps users inspect suspicious digital content before they click, pay, reply, or share personal information. It combines **Gemini semantic analysis**, **deterministic security signals**, **safe network metadata**, and **sourced Malaysian threat intelligence** into one explainable risk report.

It started as a **Project 2030: MyAI Future Hackathon** prototype by **MyviVroomVroom**. The current system is being rebuilt into something more useful than a hackathon demo: an auditable fraud-analysis and verification platform where AI is part of the judgement, **not the entire judgement**.

---

## 🔗 Project links

| Link | Destination |
| --- | --- |
| 🌐 **Original Live Demo** | [shieldscan-frontend.onrender.com](https://shieldscan-frontend.onrender.com) |
| ⚡ **Backend API** | [shieldscan-backend-esbt.onrender.com](https://shieldscan-backend-esbt.onrender.com) |
| 💚 **Backend Health** | [shieldscan-backend-esbt.onrender.com/api/health](https://shieldscan-backend-esbt.onrender.com/api/health) |
| 📺 **5-Minute Pitch Video** | [YouTube](https://youtu.be/ghL32WbbNEw) |
| 📊 **Pitch Deck** | [Google Slides](https://docs.google.com/presentation/d/1Jbwn01U6QiXHhrnqZCxwgVfeUZSHYf_P3s38hspAJmQ/edit?usp=sharing) |
| 🚀 **Vercel frontend config** | [`frontend/vercel.json`](frontend/vercel.json) |

> ℹ️ The original public demo above is the Render-hosted hackathon deployment. The current production-oriented frontend configuration targets **Vercel**, but a specific public `*.vercel.app` deployment URL is not stored in this repository yet.

[![Vercel](https://img.shields.io/badge/Frontend-Vercel-000000?logo=vercel)](https://vercel.com)
[![Render](https://img.shields.io/badge/Backend-Render-46E3B7?logo=render)](https://render.com)
[![Gemini](https://img.shields.io/badge/AI-Gemini-8E24AA?logo=google)](https://ai.google.dev)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter%20Web-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)

---

## 🎯 The problem

Scam checking is surprisingly messy for an ordinary user.

A suspicious item may arrive as a **URL**, a WhatsApp/SMS **message**, or a **screenshot**. The user then has to figure out several different questions:

- Does the link imitate a Malaysian bank or trusted brand?
- Is the domain unusually new or technically suspicious?
- Does the wording resemble phishing, impersonation, investment, or credential-stealing patterns?
- Has a similar scam pattern appeared in official Malaysian guidance?
- Is HTTPS actually meaningful here, or is the scam site simply using a valid certificate too?
- Most importantly: **what should I do next?**

A plain LLM prompt can sound convincing, but it can also hallucinate evidence or turn vague wording into an overconfident verdict. A simple URL checker has the opposite problem: it may inspect the domain but miss the meaning of the message or screenshot.

### ShieldScan's approach

Instead of asking one model to decide everything, ShieldScan separates the job into layers:

**understand the content → collect verifiable signals → retrieve relevant intelligence → assemble a bounded risk score → explain the result**.

That separation is the core idea behind the project.

---

## 💡 The solution

ShieldScan accepts three types of input:

| Input | Example | What ShieldScan can inspect |
| --- | --- | --- |
| 🔗 **URL** | A suspicious banking/login link | URL structure, brand lookalikes, DNS, TLS, domain registration metadata, semantic context |
| 💬 **Text** | SMS / WhatsApp / email copy | Scam language, social-engineering patterns, semantic indicators, related threat intelligence |
| 🖼️ **Screenshot** | Scam chat, fake notice, payment request | Multimodal semantic analysis, extracted fraud indicators, semantic threat-intel retrieval |

The result is not just a red/green badge. ShieldScan returns:

- a **risk level and risk score**;
- the **evidence that affected the score**;
- semantic fraud indicators detected by Gemini;
- related **provenance-bearing Malaysian threat intelligence**;
- an English and Bahasa Malaysia explanation;
- practical next-step recommendations.

> 🧠 **Gemini helps ShieldScan understand. The risk engine decides how evidence affects the score. Official-source retrieval helps ShieldScan ground what it says.**

---

## 👤 User flow

The user experience is intentionally simple even though the backend is doing several things.

```text
1. User opens ShieldScan
        ↓
2. Chooses URL / Text / Screenshot
        ↓
3. Pastes or uploads suspicious content
        ↓
4. ShieldScan shows the analysis pipeline progressing
        ↓
   Semantic analysis
        ↓
   Security & network evidence
        ↓
   Malaysian threat-intelligence retrieval
        ↓
   Grounded report generation
        ↓
5. User receives one explainable result
        ↓
   Risk level + score
   Why it was flagged
   Technical evidence
   Related official intelligence
   Recommended action
        ↓
6. User can verify before clicking, paying, replying,
   or sharing sensitive information
```

For a normal user, the important part is: **submit suspicious thing → see why it looks risky → know what to do next**. The technical layers stay underneath instead of making the user become a cybersecurity analyst first. 😭

---

## ⚙️ How ShieldScan actually works

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
│ explain evidence + next steps │
└──────────────┬────────────────┘
               ↓
┌───────────────────────────────┐
│ Explainable bilingual report  │
└───────────────────────────────┘
```

### 1. 🧠 Semantic & multimodal analysis

Gemini interprets what the submitted content is trying to communicate. This is useful for things deterministic rules are bad at: urgency, impersonation language, suspicious payment instructions, credential requests, and screenshot context.

For screenshots, **raw base64 is never used as a retrieval query**. ShieldScan first creates a bounded semantic query from the model's summary and fraud indicators, then searches threat intelligence using that text.

### 2. 🔍 Deterministic URL intelligence

For URL scans, ShieldScan checks explainable signals such as:

- HTTPS usage;
- raw-IP hostnames;
- punycode;
- suspicious TLDs;
- unusual ports;
- hostname shape / entropy;
- Malaysian-brand lookalikes;
- credential-bait paths and account-verification wording.

These signals become typed evidence objects instead of disappearing inside an AI prompt.

### 3. 🌐 Safe network intelligence

URL scans can also collect bounded infrastructure metadata:

- **DNS** resolution and public/non-public IP classification;
- **TLS** certificate validation against a previously validated public IP while preserving the original hostname for SNI;
- **RDAP** registration metadata through a fixed provider endpoint, including domain-age signals when available.

ShieldScan deliberately does **not** fetch the submitted webpage, execute JavaScript, follow its redirects, or submit forms. In other words: we are building a scam detector, not making the backend click scam links for fun. 🤡

And yes: a valid TLS certificate is useful metadata, but **HTTPS ≠ safe**. Scam sites can have perfectly valid certificates too.

### 4. 🇲🇾 Malaysian threat intelligence

The versioned corpus contains provenance-bearing records based on official/public material from sources such as **Bank Negara Malaysia (BNM)**, **Polis Diraja Malaysia (PDRM)**, and **Malaysian Communications and Multimedia Commission (MCMC)**.

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

Records have evidence roles so ShieldScan does not confuse *“call NSRC after being scammed”* with *“this input is evidence of a scam”*:

| Evidence role | Purpose |
| --- | --- |
| `threat_pattern` | Can support matching against known scam patterns |
| `response_guidance` | Victim-response / reporting advice only |
| `context_only` | Background context |

A retrieved match is **related intelligence, not proof** that the submitted item is fraudulent.

### 5. 🧮 Risk scoring

Current score bands are:

| Risk score | Level | Meaning |
| ---: | --- | --- |
| 0–19 | 🟢 SAFE | Few current risk signals |
| 20–39 | 🔵 LOW | Some caution warranted |
| 40–64 | 🟡 MEDIUM | Multiple or meaningful warning signs |
| 65–84 | 🟠 HIGH | Strong evidence of suspicious behaviour |
| 85–100 | 🔴 CRITICAL | Very strong combined risk signals |

These are **engineering thresholds, not calibrated fraud probabilities**.

The API deliberately separates:

- `risk_score` — final ShieldScan risk score;
- `ai_confidence_score` — Gemini's self-reported confidence;
- `deterministic_score` — deterministic evidence contribution;
- `risk_evidence` — typed security/network evidence;
- `threat_intel_matches` — sourced related intelligence;
- `scoring_version` — scoring-policy version.

Legacy `confidence_score` and `rag_matches` fields are temporarily retained for client compatibility. See [`docs/API_COMPATIBILITY.md`](docs/API_COMPATIBILITY.md).

---

## 🏗️ Architecture & tech stack

| Layer | Technology | Job |
| --- | --- | --- |
| 🎨 Frontend | Flutter Web | Scan UI, SSE progress, explainable result presentation |
| ⚡ Backend | FastAPI + Python | API, orchestration, risk engine, security controls |
| 🧠 AI reasoning | Gemini via Google Gen AI SDK | Semantic + multimodal understanding and grounded synthesis |
| 🔎 Semantic retrieval | LanceDB + multilingual sentence-transformer | Local threat-intelligence search |
| ☁️ Optional managed retrieval | Vertex AI Search | Alternative managed retrieval provider |
| 🇲🇾 Threat-intel corpus | Versioned JSON + controlled ingestion scripts | Provenance-bearing Malaysian fraud intelligence |
| 🌐 Network intelligence | DNS + TLS + RDAP | Bounded URL infrastructure evidence |
| 🚀 Frontend deployment | Vercel | Flutter Web hosting |
| 🐍 Backend deployment | Render | FastAPI service + LanceDB index build |
| ✅ CI | GitHub Actions | Backend tests + Flutter analysis/tests |

---

## 🚀 Deployment

### Current deployment shape

```text
                 GitHub
                   │
          ┌────────┴────────┐
          ↓                 ↓
       Vercel             Render
   Flutter Web UI      FastAPI backend
          │                 │
          │ API / SSE       ├─ Gemini API
          └────────────────→├─ LanceDB local index
                            ├─ DNS / TLS metadata
                            └─ fixed RDAP provider
```

### Frontend — Vercel

`frontend/vercel.json` builds Flutter Web from the stable Flutter channel and injects the backend address through `API_BASE_URL`.

```text
frontend/
  ↓
flutter pub get
  ↓
flutter build web --release
  ↓
Vercel serves build/web
```

The SPA rewrite sends application routes back to `index.html`.

### Backend — Render

`render.yaml` currently configures a Python 3.12 web service in the Singapore region.

During deployment Render runs:

```bash
pip install -r requirements-rag.txt
python scripts/build_threat_index.py
```

Then starts:

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

This means **you do not need to manually clone the repo on a laptop and build LanceDB for production**. The semantic index is built where the backend is deployed from the versioned corpus in the repository.

Current deployment configuration uses:

```text
SHIELDSCAN_RETRIEVAL_PROVIDER=lancedb
SHIELDSCAN_LANCEDB_PATH=data/lancedb
GEMINI_MODEL=gemini-3.5-flash
```

`GEMINI_API_KEY` must be configured as a deployment secret and is not committed to the repository.

> ⚠️ The production-grade work described here is currently on `upgrade/production-grade-v1` / draft PR #2. Do not assume the existing public deployment is running every feature in this README until that branch has been deliberately deployed and verified.

---

## 🔌 API

### `POST /api/scan`
Returns one complete JSON result.

### `POST /api/scan/stream`
Streams the four analysis stages and final result through **Server-Sent Events (SSE)**, which is what the Flutter UI uses for visible progress.

### `GET /api/health`
Backend health/configuration endpoint used by the service health check.

When the backend is running, FastAPI interactive documentation is available at `/docs`.

---

## 🔐 Safety, privacy & abuse controls

A fraud checker should not become another unsafe system itself.

Current controls include:

- request-body size limits on scan endpoints;
- per-client in-process sliding-window rate limiting;
- request IDs and response-latency metadata;
- metadata-only operational logging — submitted URLs/text/images are not intentionally logged;
- no scan-history database in the current service;
- SSRF-aware public-address checks before user-derived hosts are used for network metadata;
- direct-IP TLS validation after address validation to reduce DNS-rebinding/TOCTOU exposure;
- no arbitrary submitted-page fetching.

Network-provider or retrieval failures **never become SAFE evidence**.

More detail lives in:

- [`docs/SECURITY_MODEL.md`](docs/SECURITY_MODEL.md)
- [`docs/PRIVACY_AND_RETENTION.md`](docs/PRIVACY_AND_RETENTION.md)

---

## 🧪 Testing & evaluation

The repository has separate **Backend CI** and **Frontend CI** workflows.

Deterministic regression coverage includes examples such as:

- official Malaysian banking URLs;
- lookalike banking domains;
- IP-host credential bait;
- phishing and investment threat-intel positives;
- benign banking discussions that should **not** become scam matches;
- response guidance that must not be mistaken for fraud evidence;
- screenshot retrieval-query construction and base64 exclusion;
- DNS/TLS/RDAP network-intelligence behaviour;
- API compatibility between the new and legacy response fields.

Gemini's generated wording is intentionally not asserted like deterministic code in ordinary CI because generative output can change between model revisions and runs.

See [`docs/EVALUATION.md`](docs/EVALUATION.md) for the current evaluation approach and calibration limitations.

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

Useful optional configuration:

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

---

## 🗂️ Threat-intelligence maintenance

Official-source ingestion is deliberately controlled instead of silently scraping the internet during every scan.

```text
Official BNM / PDRM / MCMC source
        ↓
source-specific ingestion script
        ↓
review provenance + corpus diff
        ↓
run tests / evaluation fixtures
        ↓
rebuild LanceDB index
        ↓
deploy
```

This keeps the corpus reviewable and avoids treating arbitrary third-party pages as authoritative intelligence.

---

## 🚧 What ShieldScan does *not* claim yet

The project is intentionally explicit about unfinished production work:

- risk thresholds and network weights are not statistically calibrated yet;
- the curated Malaysian corpus is useful but not exhaustive;
- screenshot quality still needs a larger labelled evaluation set;
- RDAP data can be incomplete or provider-dependent;
- the backend does not inspect arbitrary webpage content or redirect chains;
- there is no commercial malware/domain-reputation feed yet;
- the current rate limiter is in-process rather than shared across multiple instances;
- the feature branch still needs representative end-to-end deployment verification.

So no, ShieldScan is not claiming to be a magical **100% scam detector™**. The goal is a safer and more explainable decision-support system with evidence the user can actually inspect.

---

## 🛣️ Where this is going

The next production-oriented improvements are focused on:

1. expanding labelled URL/text/screenshot evaluation data and measuring precision/recall;
2. moving rate-limit state to a shared store for multi-instance deployments;
3. adding optional commercial reputation intelligence without unsafe arbitrary-page fetching;
4. validating the full feature branch through representative deployed end-to-end scans.

See [`docs/PRODUCTION_ROADMAP.md`](docs/PRODUCTION_ROADMAP.md) for the engineering roadmap.

---

## 🏁 Project origin

ShieldScan was originally created by **MyviVroomVroom** for **Project 2030: MyAI Future Hackathon — Track 5: Secure Digital**.

The original prototype proved the interaction idea: scan suspicious digital content and make fraud checking easier for Malaysian users. The current version keeps that simple user experience while rebuilding the internals around **evidence, provenance, safer networking, evaluation, and clearer system boundaries**.

---

## ⚠️ Responsible use

ShieldScan is a **decision-support tool**, not a guarantee that something is safe or fraudulent. Users should still verify suspicious financial requests through the institution's official channels and use current Malaysian reporting/response channels when a scam is suspected.

**Think before you click. Verify before you pay. 🛡️**