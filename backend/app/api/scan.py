import json
import time
import asyncio
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from app.models.scan import ScanRequest, ScanResult
from app.services.gemini_service import analyze_fraud
from app.services.rag_service import search_rag_database

router = APIRouter()


def sse_event(data: dict) -> str:
    return f"data: {json.dumps(data)}\n\n"


async def stream_scan(request: ScanRequest):
    """Agentic 4-step fraud analysis pipeline with SSE streaming."""

    # Step 1: Classify input
    yield sse_event({"type": "step", "step": 1, "status": "running",
                     "label": "Classifying input type"})
    await asyncio.sleep(0.3)
    input_label = {"url": "URL", "text": "Text Message", "image": "Image/Screenshot"}
    yield sse_event({"type": "step", "step": 1, "status": "done",
                     "label": f"Input classified as: {input_label.get(request.type, 'Unknown')}",
                     "duration_ms": 300})

    # Step 2: Gemini Analysis
    yield sse_event({"type": "step", "step": 2, "status": "running",
                     "label": "Gemini 1.5 Pro multimodal analysis"})
    t2 = time.time()
    try:
        result: ScanResult = await asyncio.get_event_loop().run_in_executor(
            None, analyze_fraud, request.type, request.content
        )
        step2_ms = int((time.time() - t2) * 1000)
        yield sse_event({"type": "step", "step": 2, "status": "done",
                         "label": "Gemini analysis complete",
                         "duration_ms": step2_ms})
    except Exception as e:
        yield sse_event({"type": "step", "step": 2, "status": "error",
                         "label": f"Analysis error: {str(e)}"})
        yield sse_event({"type": "done"})
        return

    # Step 3: RAG cross-reference
    yield sse_event({"type": "step", "step": 3, "status": "running",
                     "label": "Cross-referencing PDRM/BNM/MCMC fraud database"})
    t3 = time.time()
    rag_matches = search_rag_database(request.content, result.threat_level)
    result.rag_matches = rag_matches
    step3_ms = int((time.time() - t3) * 1000)
    yield sse_event({"type": "step", "step": 3, "status": "done",
                     "label": f"Found {len(rag_matches)} matching fraud pattern(s)",
                     "duration_ms": step3_ms})

    # Step 4: Report generation
    yield sse_event({"type": "step", "step": 4, "status": "running",
                     "label": "Generating bilingual threat report"})
    await asyncio.sleep(0.2)
    yield sse_event({"type": "step", "step": 4, "status": "done",
                     "label": "Bilingual report ready (EN + BM)",
                     "duration_ms": 200})

    # Final result
    yield sse_event({
        "type": "result",
        "threat_level": result.threat_level,
        "confidence_score": result.confidence_score,
        "summary_en": result.summary_en,
        "summary_bm": result.summary_bm,
        "indicators": [i.dict() for i in result.indicators],
        "recommendation_en": result.recommendation_en,
        "recommendation_bm": result.recommendation_bm,
        "rag_matches": result.rag_matches,
        "scan_duration_ms": result.scan_duration_ms,
    })
    yield sse_event({"type": "done"})


@router.post("/scan/stream")
async def scan_stream(request: ScanRequest):
    """Streaming SSE endpoint for real-time agent step updates."""
    return StreamingResponse(
        stream_scan(request),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        }
    )


@router.post("/scan", response_model=ScanResult)
async def scan(request: ScanRequest):
    """Standard JSON endpoint for single-call scan."""
    result = await asyncio.get_event_loop().run_in_executor(
        None, analyze_fraud, request.type, request.content
    )
    rag_matches = search_rag_database(request.content, result.threat_level)
    result.rag_matches = rag_matches
    return result
