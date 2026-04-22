#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# ShieldScan AI — Cloud Run Deployment Script
# Usage: chmod +x deploy.sh && ./deploy.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Config ────────────────────────────────────────────────────────────────────
PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="asia-southeast1"
BACKEND_SERVICE="shieldscan-backend"
FRONTEND_SERVICE="shieldscan-frontend"
REPO="gcr.io/${PROJECT_ID}"

echo "🛡️  ShieldScan AI — Deploying to Google Cloud Run"
echo "📍 Project: ${PROJECT_ID} | Region: ${REGION}"
echo ""

# ── Step 0: Prerequisites check ───────────────────────────────────────────────
if ! command -v gcloud &> /dev/null; then
  echo "❌ gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

if [ -z "${GEMINI_API_KEY}" ]; then
  echo "❌ GEMINI_API_KEY not set. Run: export GEMINI_API_KEY=your_key"
  exit 1
fi

# ── Step 1: Authenticate & set project ───────────────────────────────────────
echo "🔐 Step 1/5 — Authenticating..."
gcloud config set project "${PROJECT_ID}"
gcloud services enable run.googleapis.com containerregistry.googleapis.com --quiet
echo "✅ Auth done"

# ── Step 2: Build & push backend ─────────────────────────────────────────────
echo ""
echo "🔨 Step 2/5 — Building backend Docker image..."
docker build -t "${REPO}/${BACKEND_SERVICE}:latest" ./backend
docker push "${REPO}/${BACKEND_SERVICE}:latest"
echo "✅ Backend image pushed"

# ── Step 3: Deploy backend to Cloud Run ───────────────────────────────────────
echo ""
echo "🚀 Step 3/5 — Deploying backend to Cloud Run..."
gcloud run deploy "${BACKEND_SERVICE}" \
  --image "${REPO}/${BACKEND_SERVICE}:latest" \
  --platform managed \
  --region "${REGION}" \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars "GEMINI_API_KEY=${GEMINI_API_KEY}" \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT:-}" \
  --set-env-vars "VERTEX_SEARCH_ENGINE_ID=${VERTEX_SEARCH_ENGINE_ID:-}" \
  --quiet

BACKEND_URL=$(gcloud run services describe "${BACKEND_SERVICE}" \
  --region "${REGION}" --format "value(status.url)")
echo "✅ Backend live at: ${BACKEND_URL}"

# ── Step 4: Build & push frontend with backend URL ────────────────────────────
echo ""
echo "🔨 Step 4/5 — Building Flutter Web frontend..."
docker build \
  --build-arg "API_BASE_URL=${BACKEND_URL}" \
  -t "${REPO}/${FRONTEND_SERVICE}:latest" \
  ./frontend
docker push "${REPO}/${FRONTEND_SERVICE}:latest"
echo "✅ Frontend image pushed"

# ── Step 5: Deploy frontend to Cloud Run ──────────────────────────────────────
echo ""
echo "🚀 Step 5/5 — Deploying frontend to Cloud Run..."
gcloud run deploy "${FRONTEND_SERVICE}" \
  --image "${REPO}/${FRONTEND_SERVICE}:latest" \
  --platform managed \
  --region "${REGION}" \
  --allow-unauthenticated \
  --memory 256Mi \
  --cpu 1 \
  --max-instances 5 \
  --quiet

FRONTEND_URL=$(gcloud run services describe "${FRONTEND_SERVICE}" \
  --region "${REGION}" --format "value(status.url)")

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "✅  DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Frontend (submit this):  ${FRONTEND_URL}"
echo "⚙️  Backend API:             ${BACKEND_URL}"
echo "📋 Health check:            ${BACKEND_URL}/api/health"
echo ""
echo "📌 Add to your submission form:"
echo "   Cloud Run URL: ${FRONTEND_URL}"
echo ""
