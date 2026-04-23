#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# ShieldScan AI — Cloud Run Deployment (NO DOCKER REQUIRED)
# Uses gcloud source deploy — Google builds the container for you
# ─────────────────────────────────────────────────────────────────────────────

set -e

PROJECT_ID="${GCP_PROJECT_ID:-shieldscan-ai-494109}"
REGION="asia-southeast1"
BACKEND_SERVICE="shieldscan-backend"
FRONTEND_SERVICE="shieldscan-frontend"

echo "🛡️  ShieldScan AI — Deploying to Google Cloud Run"
echo "📍 Project: ${PROJECT_ID} | Region: ${REGION}"
echo ""

# ── Check Gemini API Key ───────────────────────────────────────────────────────
if [ -z "${GEMINI_API_KEY}" ]; then
  echo "❌ GEMINI_API_KEY not set."
  echo "   Run: export GEMINI_API_KEY=your_key_here"
  exit 1
fi

# ── Enable required APIs ──────────────────────────────────────────────────────
echo "🔐 Step 1/4 — Enabling Cloud APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com --quiet
echo "✅ APIs enabled"

# ── Deploy Backend (source deploy — no Docker needed!) ────────────────────────
echo ""
echo "🚀 Step 2/4 — Deploying backend (Google will build it for you)..."
echo "   This takes 2-4 minutes on first deploy..."

gcloud run deploy "${BACKEND_SERVICE}" \
  --source ./backend \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars "GEMINI_API_KEY=${GEMINI_API_KEY}" \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT:-}" \
  --set-env-vars "VERTEX_SEARCH_ENGINE_ID=${VERTEX_SEARCH_ENGINE_ID:-}" \
  --quiet

BACKEND_URL=$(gcloud run services describe "${BACKEND_SERVICE}" \
  --region "${REGION}" \
  --format "value(status.url)")

echo "✅ Backend live at: ${BACKEND_URL}"

# ── Build Flutter Web locally ─────────────────────────────────────────────────
echo ""
echo "🔨 Step 3/4 — Building Flutter Web frontend..."

if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found. Install from: https://flutter.dev/docs/get-started/install"
  exit 1
fi

cd frontend
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="${BACKEND_URL}"
cd ..

echo "✅ Flutter build complete"

# ── Deploy Frontend (source deploy) ──────────────────────────────────────────
echo ""
echo "🚀 Step 4/4 — Deploying frontend..."

# Create a minimal Dockerfile just for serving the built files
# (gcloud source deploy needs this for the frontend)
cat > frontend/Dockerfile.serve << 'EOF'
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
EOF

# Rename temporarily so gcloud uses it
mv frontend/Dockerfile frontend/Dockerfile.flutter
mv frontend/Dockerfile.serve frontend/Dockerfile

gcloud run deploy "${FRONTEND_SERVICE}" \
  --source ./frontend \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --memory 256Mi \
  --cpu 1 \
  --max-instances 5 \
  --quiet

# Restore original Dockerfile
mv frontend/Dockerfile frontend/Dockerfile.serve
mv frontend/Dockerfile.flutter frontend/Dockerfile

FRONTEND_URL=$(gcloud run services describe "${FRONTEND_SERVICE}" \
  --region "${REGION}" \
  --format "value(status.url)")

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "✅  DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Frontend (submit this URL): ${FRONTEND_URL}"
echo "⚙️  Backend API:                ${BACKEND_URL}"
echo "📋 Health check:               ${BACKEND_URL}/api/health"
echo ""
echo "📌 Paste this into your submission form:"
echo "   ${FRONTEND_URL}"
echo ""