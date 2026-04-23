import os
import json
import time
import base64
import re
from google import genai
from google.genai import types
from app.models.scan import ScanResult, ThreatLevel, FraudIndicator

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", ""))

FRAUD_ANALYSIS_PROMPT = """
You are ShieldScan AI, Malaysia's leading fraud detection expert. You have deep knowledge of:
- Malaysian scam patterns: Macau Scams, WhatsApp prize scams, banking phishing
- Local fraud tactics targeting Maybank2u, CIMB Clicks, Touch 'n Go users
- Bahasa Malaysia fraud phrases and social engineering tactics
- PDRM (Royal Malaysia Police) and BNM (Bank Negara Malaysia) fraud databases

Analyze the following {input_type} for fraud indicators:

INPUT: {content}

Respond ONLY with a valid JSON object (no markdown, no backticks) with this exact structure:
{{
  "threat_level": "SAFE|LOW|MEDIUM|HIGH|CRITICAL",
  "confidence_score": <0-100 integer>,
  "summary_en": "<2-3 sentence English summary of findings>",
  "summary_bm": "<2-3 sentence Bahasa Malaysia summary of findings>",
  "indicators": [
    {{"category": "<category>", "description": "<what was found>", "severity": "low|medium|high"}}
  ],
  "recommendation_en": "<clear English action for the user>",
  "recommendation_bm": "<clear Bahasa Malaysia action for the user>",
  "rag_matches": ["<similar known fraud case 1>", "<similar known fraud case 2>"]
}}

Threat Level Guidelines:
- SAFE: No fraud indicators. Legitimate content.
- LOW: Minor suspicious elements. Proceed with caution.
- MEDIUM: Multiple fraud signals. Verify before proceeding.
- HIGH: Strong fraud indicators. Do not proceed.
- CRITICAL: Confirmed fraud pattern. Report immediately to PDRM/BNM.

Be precise. Real Malaysians depend on this analysis.
"""


def analyze_fraud(input_type: str, content: str) -> ScanResult:
    start = time.time()

    prompt = FRAUD_ANALYSIS_PROMPT.format(
        input_type=input_type.upper(),
        content=content if input_type != "image" else "[Image attached]"
    )

    if input_type == "image":
        try:
            image_bytes = base64.b64decode(content)
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
                    types.Part.from_text(text=prompt),
                ]
            )
        except Exception:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt
            )
    else:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )

    raw = response.text.strip()
    raw = re.sub(r"```json|```", "", raw).strip()

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = {
            "threat_level": "MEDIUM",
            "confidence_score": 50,
            "summary_en": "Analysis completed. Manual review recommended.",
            "summary_bm": "Analisis selesai. Semakan manual disyorkan.",
            "indicators": [],
            "recommendation_en": "Please verify this content through official channels.",
            "recommendation_bm": "Sila sahkan kandungan ini melalui saluran rasmi.",
            "rag_matches": []
        }

    duration_ms = int((time.time() - start) * 1000)

    return ScanResult(
        threat_level=ThreatLevel(data.get("threat_level", "MEDIUM")),
        confidence_score=data.get("confidence_score", 50),
        summary_en=data.get("summary_en", ""),
        summary_bm=data.get("summary_bm", ""),
        indicators=[FraudIndicator(**i) for i in data.get("indicators", [])],
        recommendation_en=data.get("recommendation_en", ""),
        recommendation_bm=data.get("recommendation_bm", ""),
        rag_matches=data.get("rag_matches", []),
        scan_duration_ms=duration_ms
    )