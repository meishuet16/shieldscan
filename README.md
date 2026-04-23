# 🛡️ ShieldScan AI
### Malaysia Fraud Intelligence Hub — Project 2030 Hackathon · Track 5: Secure Digital

> **"Jaga Digital Malaysia"** — Protecting every Malaysian before they click.

## 🔗 Official Submission Links
- **🌐 Live Demo (Cloud Run):** [https://shieldscan-frontend-oci6nmhk5q-as.a.run.app/](https://shieldscan-frontend-oci6nmhk5q-as.a.run.app/)
- **📺 5-Minute Pitch Video:** [https://youtu.be/Zv4mhR2pp4s](https://youtu.be/Zv4mhR2pp4s)
- **📊 Pitch Deck:** [https://docs.google.com/presentation/d/1Jbwn01U6QiXHhrnqZCxwgVfeUZSHYf_P3s38hspAJmQ/edit?usp=sharing](https://docs.google.com/presentation/d/1Jbwn01U6QiXHhrnqZCxwgVfeUZSHYf_P3s38hspAJmQ/edit?usp=sharing)

---

[![Cloud Run](https://img.shields.io/badge/Deployed%20on-Cloud%20Run-4285F4?logo=google-cloud)](https://your-cloudrun-url.a.run.app)
[![Gemini](https://img.shields.io/badge/Powered%20by-Gemini%202.5%20Flash-8E24AA?logo=google)](https://ai.google.dev)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter%20Web-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Track](https://img.shields.io/badge/Track%205-Secure%20Digital-FF3B5C)](https://gdgutm.com)

---

## 🎯 Problem & Solution

### The Problem
Digital fraud costs Malaysian citizens **hundreds of millions of ringgit annually**. Attacks include Macau Scams, banking phishing targeting Maybank2u/CIMB, WhatsApp prize scams, and fake investment schemes. Victims — especially the elderly and those less familiar with digital platforms — often cannot distinguish real communications from sophisticated fakes.

### Our Solution: ShieldScan AI
A **multimodal, agentic fraud detection platform** that lets any Malaysian paste a suspicious URL, text message, or upload a screenshot — and receive a real-time threat analysis powered by **Gemini 2.5 Flash** in under 10 seconds, with results in both **English and Bahasa Malaysia**.

**ShieldScan directly addresses Malaysia's national priorities:**
| Framework | Alignment |
|-----------|-----------|
| **NIMP 2030** | Builds indigenous AI-powered security infrastructure |
| **MyDIGITAL** | Advances digital economy safety and public trust |
| **Malaysia Madani** | Protects the rakyat from financial harm |
| **BNM / PDRM / MCMC** | Complements existing fraud reporting systems |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Flutter Web (Cloud Run)                     │
│  [URL Input] [Text Input] [Image Upload]                 │
│         ↓ SSE Streaming (real-time agent steps)         │
└──────────────────────┬──────────────────────────────────┘
                       │ POST /api/scan/stream
┌──────────────────────▼──────────────────────────────────┐
│              FastAPI Backend (Cloud Run)                 │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Agentic Workflow — 4 Steps               │    │
│  │                                                  │    │
│  │  Step 1: Input Classifier                        │    │
│  │      ↓                                           │    │
│  │  Step 2: Gemini 2.5 Flash Multimodal Analysis ────→│──→ Google AI API
│  │      ↓                                           │    │
│  │  Step 3: Vertex AI Search RAG ──────────────────→│──→ Fraud Database
│  │      ↓                                           │    │
│  │  Step 4: Bilingual Report Generator              │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## 🧠 Google AI Ecosystem Stack

| Component | Technology | Role |
|-----------|-----------|------|
| **AI Brain** | Gemini 2.5 Flash | Core multimodal fraud analysis (URL + text + image) |
| **Orchestration** | Vertex AI Agent Builder (Logic formulation) & Genkit-inspired Pipeline | 4-step reasoning workflow with SSE streaming |
| **RAG** | Vertex AI Search | Malaysian fraud case database (PDRM/BNM/MCMC) |
| **Development** | Google AI Studio | Prompt engineering & API testing |
| **Deployment** | Google Cloud Run | Serverless containerized hosting |

> *Note for MVP: The current Vertex AI Search index uses a curated dataset of public scam alerts scraped from BNM Amarans and news reports.*

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- Flutter 3.22+ (`flutter doctor`)
- Python 3.12+
- Docker & Docker Compose (optional)
- [Gemini API Key](https://aistudio.google.com/app/apikey) — **free**

### 1. Clone & Configure
```bash
git clone https://github.com/meishuet16/shieldscan.git
cd shieldscan
cp .env.example .env
# Edit .env → add your GEMINI_API_KEY
```

### 2. Run Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
# API docs: http://localhost:8080/docs
```

### 3. Run Flutter Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

### 4. Or: Docker Compose (one command)
```bash
docker-compose up --build
# Frontend: http://localhost:3000
# Backend:  http://localhost:8080
# API docs: http://localhost:8080/docs
```

---

## ☁️ Deploy to Google Cloud Run

```bash
export GCP_PROJECT_ID=shieldscan-ai-494109
export GEMINI_API_KEY=your-gemini-api-key

chmod +x deploy.sh && ./deploy.sh
```

---

## 🎯 Features

### Multimodal Scanning
- **🔗 URL Analysis** — Domain age, SSL validity, brand impersonation, suspicious TLDs
- **💬 Text Analysis** — Urgency patterns, prize scams, Bahasa Malaysia fraud phrases, impersonation
- **🖼️ Image Analysis** — Fake login pages, fake receipts, WhatsApp scam screenshots

### Threat Levels
| Level | Indicator | Meaning |
|-------|-----------|---------|
| SAFE | 🟢 | No fraud indicators detected |
| LOW | 🟡 | Minor suspicious elements — proceed with caution |
| MEDIUM | 🟠 | Multiple fraud signals — verify before proceeding |
| HIGH | 🔴 | Strong fraud indicators — do not proceed |
| CRITICAL | 🚨 | Confirmed fraud pattern — report immediately |

### Real-time Agentic Steps (SSE Streaming)
The UI streams each agent step live as Gemini works:
```
✅ Step 1: Input classified as: URL                (0.3s)
✅ Step 2: Gemini 2.5 flash analysis complete        (3.2s)
✅ Step 3: Found 2 matching fraud pattern(s)       (0.8s)
✅ Step 4: Bilingual report ready (EN + BM)        (0.2s)
```

### Bilingual Output
All reports are delivered in **English + Bahasa Malaysia** — making fraud protection accessible to all Malaysians.

### 🛡️ ScamShield-Inspired Defenses 
- **🚩 One-Click Reporting:** Users can flag unrecognised threats to simulate crowdsourced threat intelligence feeding into the PDRM/CCID database.
- **🔥 Trending Scams Dashboard:** A live-feed UI displaying the latest active fraud patterns in Malaysia to proactively educate users.
- **🚀 Transparent Roadmap:** Built-in UI section outlining Phase 2 & 3 (WhatsApp Bot & Native App Background Scanning) to demonstrate long-term commercial viability.

---

## 📁 Project Structure

```
shieldscan/
├── backend/                        # FastAPI + Gemini 2.5 Flash
│   ├── main.py                     # App entry point + CORS
│   ├── app/
│   │   ├── api/
│   │   │   ├── scan.py             # Scan endpoint + SSE streaming
│   │   │   └── health.py           # Health check
│   │   ├── models/
│   │   │   └── scan.py             # Pydantic data models
│   │   └── services/
│   │       ├── gemini_service.py   # Gemini 2.5 Flash integration
│   │       └── rag_service.py      # Vertex AI Search / RAG
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend/                       # Flutter Web
│   ├── lib/
│   │   ├── main.dart               # App entry + Material theme
│   │   ├── screens/
│   │   │   └── home_screen.dart    # Main dashboard
│   │   ├── widgets/
│   │   │   ├── stats_banner.dart   # Live statistics banner
│   │   │   ├── input_panel.dart    # Multimodal input (URL/text/image)
│   │   │   ├── agent_steps_panel.dart  # Real-time streaming steps
│   │   │   └── result_card.dart    # Bilingual threat report card
│   │   │   ├── trending_scams.dart     
│   │   │   └── roadmap_section.dart     
│   │   └── services/
│   │       └── scan_provider.dart  # State management + API calls
│   ├── web/
│   │   └── index.html              # Web entry point
│   ├── pubspec.yaml
│   ├── nginx.conf
│   └── Dockerfile
│
├── docker-compose.yml              # Local development
├── deploy.sh                       # One-command Cloud Run deploy
├── .env.example                    # Environment template
├── .gitignore
└── README.md
```

---

## 🔌 API Reference

### `POST /api/scan/stream` — Streaming SSE (recommended)
```bash
curl -X POST http://localhost:8080/api/scan/stream \
  -H "Content-Type: application/json" \
  -d '{"type": "url", "content": "https://maybank2u-login.xyz/verify"}'
```

Response (Server-Sent Events):
```
data: {"type":"step","step":1,"status":"done","label":"Input classified as: URL","duration_ms":300}
data: {"type":"step","step":2,"status":"running","label":"Gemini 2.5 Flash multimodal analysis"}
data: {"type":"step","step":2,"status":"done","label":"Gemini analysis complete","duration_ms":3200}
data: {"type":"step","step":3,"status":"done","label":"Found 1 matching fraud pattern(s)","duration_ms":800}
data: {"type":"step","step":4,"status":"done","label":"Bilingual report ready (EN + BM)","duration_ms":200}
data: {"type":"result","threat_level":"CRITICAL","confidence_score":97,...}
data: {"type":"done"}
```

### `POST /api/scan` — Standard JSON
```bash
curl -X POST http://localhost:8080/api/scan \
  -H "Content-Type: application/json" \
  -d '{"type": "text", "content": "Tahniah! Anda memenangi RM5000!"}'
```

### `GET /api/health`
```json
{"status":"ok","service":"ShieldScan AI Backend","version":"1.0.0","gemini_configured":true}
```

Full interactive docs: `http://localhost:8080/docs`

---

## 🧪 Test Cases for Demo

| Input | Type | Expected |
|-------|------|---------|
| `https://maybank2u-secure-login.xyz/verify` | URL | 🚨 CRITICAL |
| `Tahniah! Anda memenangi RM5,000. Klik untuk tuntut!` | Text | 🔴 HIGH |
| `Ini Polis DiRaja Malaysia. Akaun anda disekat.` | Text | 🚨 CRITICAL |
| `https://www.maybank2u.com.my` | URL | 🟢 SAFE |
| `https://google.com` | URL | 🟢 SAFE |
| WhatsApp prize scam screenshot | Image | 🔴 HIGH/CRITICAL |

---

## 🤖 AI Tools Disclosure
*(As required by Project 2030 Code of Conduct — Section 4)*

The following AI tools were used during development:
- **Google AI Studio** — Prompt engineering and Gemini API testing
- **Gemini 2.5 Flash** — Core fraud analysis engine (production use in app)
- **Claude (Anthropic)** — Architecture planning and code assistance

---

## 👥 Team

- **Team:** MyviVroomVroom
- **Member Name:** Lee Mei Shuet
- **Track:** Track 5 — Secure Digital (FinTech & Security)
- **Event:** Project 2030: MyAI Future Hackathon by GDG On Campus UTM
- **Submission Deadline:** 24 April 2026

---

## 📞 Report Fraud (Malaysia)

| Authority | Contact |
|-----------|---------|
| PDRM Cybercrime | 03-2266 2222 |
| BNM BNMTELELINK | 1-300-88-5465 |
| MCMC Aduan | 1-800-188-030 |
| NSRC (National Scam Response Centre) | 997 |

---

*Built with ❤️ for Malaysia — "Advance the Nation by Building Solutions with Google AI"*