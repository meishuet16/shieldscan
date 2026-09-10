import json
import time
import asyncio
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from app.models.scan import ScanRequest, ScanResult
from app.services.gemini_service import analyze_fraud, synthesize_grounded_report
from app.services.rag_service import search_threat_intelligence
from app.services.risk_engine import apply_risk_engine

router = APIRouter()


def sse_event(data: dict) -> str:
    return f"data: {json.dumps(data)}\n\n"


async def stream_scan(request: ScanRequest):
    """Four-stage fraud analysis pipeline with auditable risk scoring and grounded RAG."""

    # Step 1: Validate/classify input
    yield sse_event({"type": "step", "step": 1, "status": "running",
                     "label": "Preparing input"})
    input_label = {"url": "URL", "text": "Text Message", "image": "Image/Screenshot"}
    yield sse_event({"type": "step", "step": 1, "status": "done",
                     "label": f"Input type: {input_label.get(request.type.value, 'Unknown')}",
                     "duration_ms": 0})

    # Step 2: Gemini semantic/multimodal analysis
    yield sse_event({"type": "step", "step": 2, "status": "running",
                     "label": "Running semantic fraud analysis"})
    t2 = time.time()
    try:
        result: ScanResult = await asyncio.to_thread(
            analyze_fraud, request.type.value, request.content
        )
        step2_ms = int((time.time() - t2) * 1000)
        yield sse_event({"type": "step", "step": 2, "status": "done",
                         "label": "Semantic analysis complete",
                         "duration_ms": step2_ms})
    except Exception as e:
        yield sse_event({"type": "step", "step": 2, "status": "error",
                         "label": "Analysis failed"})
        yield sse_event({"type": "error", "message": str(e)})
        yield sse_event({"type": "done"})
        return

    # Step 3: Deterministic intelligence + evidence aggregation
    yield sse_event({"type": "step", "step": 3, "status": "running",
                     "label": "Evaluating deterministic security signals"})
    t3 = time.time()
    result = apply_risk_engine(request.type.value, request.content, result)
    scoring_ms = int((time.time() - t3) * 1000)
    yield sse_event({"type": "step", "step": 3, "status": "done",
                     "label": f"Risk score assembled from {len(result.risk_evidence)} evidence signal(s)",
                     "duration_ms": scoring_ms})

    # Step 4: provenance-bearing retrieval + grounded report synthesis.
    yield sse_event({"type": "step", "step": 4, "status": "running",
                     "label": "Retrieving and grounding related threat intelligence"})
    t4 = time.time()
    # Raw image base64 is intentionally not retrieved directly. The visual semantic
    # analysis remains useful, but image-to-text retrieval needs a dedicated query step.
    intel_matches = [] if request.type.value == "image" else await asyncio.to_thread(
        search_threat_intelligence, request.content
    )
    result.rag_matches = intel_matches
    if intel_matches:
        result = await asyncio.to_thread(synthesize_grounded_report, result, intel_matches)
    step4_ms = int((time.time() - t4) * 1000)
    yield sse_event({"type": "step", "step": 4, "status": "done",
                     "label": f"Grounded report with {len(intel_matches)} sourced intelligence match(es)",
                     "duration_ms": step4_ms})

    yield sse_event({"type": "result", **result.model_dump(mode="json")})
    yield sse_event({"type": "done"})


@router.post("/scan/stream")
async def scan_stream(request: ScanRequest):
    """Streaming SSE endpoint for real-time scan progress."""
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
    """Standard JSON endpoint for a complete scan."""
    result = await asyncio.to_thread(analyze_fraud, request.type.value, request.content)
    result = apply_risk_engine(request.type.value, request.content, result)
    result.rag_matches = [] if request.type.value == "image" else await asyncio.to_thread(
        search_threat_intelligence, request.content
    )
    if result.rag_matches:
        result = await asyncio.to_thread(synthesize_grounded_report, result, result.rag_matches)
    return result
