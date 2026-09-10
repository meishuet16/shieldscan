import logging
import os
import time
import uuid

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.scan import router as scan_router
from app.api.health import router as health_router
from app.services.request_guardrails import allow_request, request_too_large

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("shieldscan")

app = FastAPI(
    title="ShieldScan AI",
    description="Malaysia Fraud Intelligence Hub — Powered by Gemini",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def production_guardrails(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or uuid.uuid4().hex
    started = time.perf_counter()

    if request.url.path.startswith("/api/scan"):
        if request_too_large(request.headers.get("content-length")):
            response = JSONResponse(
                status_code=413,
                content={"detail": "Request body is too large", "request_id": request_id},
            )
            response.headers["x-request-id"] = request_id
            return response

        client_key = request.client.host if request.client else "unknown"
        allowed, retry_after = allow_request(client_key)
        if not allowed:
            response = JSONResponse(
                status_code=429,
                content={"detail": "Too many scan requests", "request_id": request_id},
            )
            response.headers["Retry-After"] = str(retry_after)
            response.headers["x-request-id"] = request_id
            return response

    response = await call_next(request)
    duration_ms = round((time.perf_counter() - started) * 1000)
    response.headers["x-request-id"] = request_id
    response.headers["x-response-time-ms"] = str(duration_ms)

    # Deliberately log metadata only: never request bodies, uploaded images, URLs, or scan text.
    logger.info(
        "request_complete request_id=%s method=%s path=%s status=%s duration_ms=%s",
        request_id,
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
    )
    return response


app.include_router(health_router, prefix="/api")
app.include_router(scan_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
