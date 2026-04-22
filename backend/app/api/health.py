from fastapi import APIRouter
import os

router = APIRouter()


@router.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "ShieldScan AI Backend",
        "version": "1.0.0",
        "gemini_configured": bool(os.environ.get("GEMINI_API_KEY")),
        "vertex_rag_configured": bool(os.environ.get("VERTEX_SEARCH_ENGINE_ID")),
    }
