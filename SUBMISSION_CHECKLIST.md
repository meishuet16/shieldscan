# ✅ ShieldScan AI — Submission Checklist & Step-by-Step Guide
## Project 2030: MyAI Future Hackathon | Deadline: 24 April 2026 at 11:59 PM MYT

---

## 📋 REQUIRED SUBMISSION ITEMS

| Item | Status | Notes |
|------|--------|-------|
| ✅ GitHub Repo (public) with README | Ready | See README.md |
| ⬜ Video Demo (max 5 min, YouTube/Drive) | YOU DO | Record your demo |
| ⬜ Google Slides (max 15 slides, PDF) | YOU DO | See PITCH_DECK_SLIDES.md |
| ⬜ Cloud Run Deployment URL | YOU DO | Run deploy.sh |
| ⬜ Submit via Google Forms | YOU DO | forms.gle/z3J5Z4n7f16jGYfr9 |

---

## 🚀 STEP-BY-STEP SUBMISSION GUIDE

### STEP 1 — Get Your Gemini API Key (5 minutes)
1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API key"
3. Copy the key
4. `export GEMINI_API_KEY=your_key_here`

---

### STEP 2 — Push Code to GitHub (10 minutes)
```bash
# From the shieldscan/ folder:
git init
git add .
git commit -m "feat: ShieldScan AI - Malaysia Fraud Intelligence Hub"
git branch -M main

# Create a new PUBLIC repo on GitHub named "shieldscan"
# Then:
git remote add origin https://github.com/YOUR_USERNAME/shieldscan.git
git push -u origin main
```

**Important:** Make sure your repo is PUBLIC. Update the badge URLs in README.md with your actual GitHub username.

---

### STEP 3 — Deploy to Google Cloud Run (20 minutes)

#### 3a. Set up Google Cloud
1. Go to https://console.cloud.google.com
2. Create a new project (or use existing)
3. Copy your Project ID
4. Install gcloud CLI: https://cloud.google.com/sdk/docs/install
5. Run: `gcloud auth login`

#### 3b. Deploy
```bash
export GCP_PROJECT_ID=your-actual-project-id
export GEMINI_API_KEY=your-actual-gemini-key

chmod +x deploy.sh
./deploy.sh
```

#### 3c. After deploy:
- Copy the **Frontend URL** (e.g., `https://shieldscan-frontend-xxxx-as.a.run.app`)
- Test it in your browser
- Test the health check: `https://shieldscan-backend-xxxx-as.a.run.app/api/health`
- Update the Cloud Run badge in README.md with your real URL

**⚠️ If you don't have Docker locally**, you can build using Cloud Build:
```bash
gcloud builds submit --tag gcr.io/$GCP_PROJECT_ID/shieldscan-backend ./backend
```

---

### STEP 4 — Record Your Video Demo (30 minutes)

**Max 5 minutes. Must show the working prototype.**

Suggested script:
```
0:00–0:30  Introduce the problem (Malaysian fraud statistics)
0:30–1:00  Show the app UI — explain the 3 input types
1:00–2:00  DEMO 1: Scan phishing URL → watch agent steps → CRITICAL result
2:00–2:45  DEMO 2: Scan Macau scam text in BM → toggle to BM report
2:45–3:30  DEMO 3: Show SAFE result for real URL (google.com)
3:30–4:00  Show the architecture / tech stack slide briefly
4:00–4:30  Explain national alignment (NIMP 2030, MyDIGITAL)
4:30–5:00  Closing: Cloud Run URL + GitHub link + team
```

Upload to YouTube (unlisted is fine) or Google Drive (set to "Anyone with link can view").
Copy the link.

---

### STEP 5 — Create Google Slides Pitch Deck (45 minutes)

1. Open https://slides.google.com → New Presentation
2. Use PITCH_DECK_SLIDES.md as your content guide (15 slides)
3. Apply dark theme: background #0A0E1A, accent #00D4FF
4. Add Google Fonts: Space Mono (headings) + Space Grotesk (body)
5. Add your team member names on slide 14
6. Add your real Cloud Run URL and GitHub URL on slide 15
7. File → Download → PDF (.pdf)
8. Re-upload to Google Drive → copy the shareable link

**Make sure the link is set to "Anyone with link can view"**

---

### STEP 6 — Final Checks Before Submitting

Run through this list:

**GitHub Repo:**
- [ ] Repo is PUBLIC
- [ ] README.md is complete and in English
- [ ] README has: setup steps, architecture, feature list, AI disclosure
- [ ] `.env.example` is present (NOT `.env` with real keys)
- [ ] All source code is present (backend + frontend)
- [ ] No hardcoded API keys anywhere in the code

**Cloud Run:**
- [ ] Frontend URL loads in browser (no login required)
- [ ] Backend health check returns `{"status":"ok"}`
- [ ] A scan actually works end-to-end

**Video:**
- [ ] Under 5 minutes
- [ ] Shows the working prototype
- [ ] YouTube/Drive link is publicly accessible

**Slides:**
- [ ] 15 slides or fewer
- [ ] PDF downloaded
- [ ] Google Drive link is publicly accessible

---

### STEP 7 — Submit via Google Forms

**Submission Link:** https://forms.gle/z3J5Z4n7f16jGYfr9
**Submission Period:** 3 April – 24 April 2026 at 11:59 PM MYT

Have these ready to paste:
1. Team name: **ShieldScan AI**
2. Track: **Track 5: Secure Digital**
3. GitHub URL: `https://github.com/YOUR_USERNAME/shieldscan`
4. Video URL: `https://youtube.com/watch?v=...` or Google Drive link
5. Slides URL: Google Drive PDF link
6. Cloud Run URL: `https://shieldscan-frontend-xxxx-as.a.run.app`

---

## 🏆 RUBRIC ALIGNMENT CHECK

| Rubric Category | Max | Our Coverage |
|-----------------|-----|-------------|
| AI Implementation & Technical Execution | 25 | ✅ Gemini 1.5 Pro as core logic, 4-step agentic pipeline, SSE streaming, RAG, scalable Cloud Run |
| Innovation & Creativity | 20 | ✅ Bilingual output, real-time agent streaming, multimodal (URL+text+image), Malaysian-specific RAG |
| Impact & Problem Relevance | 20 | ✅ Directly addresses Malaysian fraud epidemic, NIMP 2030 + MyDIGITAL + Malaysia Madani aligned |
| UI/UX & Presentation | 10 | ✅ Dark professional UI, responsive, accessible bilingual toggle, threat level color system |
| Code Quality | 15 | ✅ Modular architecture, Pydantic models, .env pattern, full README, FastAPI auto-docs |
| Pitch / Video | 10 | ✅ Clear narrative, live demo, bilingual angle |
| **TOTAL** | **100** | **Full coverage** |

---

## ⚠️ COMMON DISQUALIFICATION RISKS — AVOID THESE

| Risk | How We Avoid It |
|------|----------------|
| Late submission | Submit by 23 April to be safe |
| Cloud Run URL requires login | `--allow-unauthenticated` flag in deploy.sh ✅ |
| Hardcoded API keys | Using env vars + .env.example ✅ |
| No AI disclosure | Section in README + Slide 14 ✅ |
| Non-English primary README | README is in English ✅ |
| No setup instructions | Full Quick Start in README ✅ |

---

## 📞 Need Help?

- **Discord:** https://discord.gg/H7AKRXSY2B
- **Email:** myaifuturehackathon@gmail.com
- **Instagram:** https://www.instagram.com/gdg.utm
