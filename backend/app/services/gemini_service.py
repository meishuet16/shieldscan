import os
import json
import time
import base64
import re
from google import genai
from google.genai import types
from app.models.scan import ScanResult, ThreatLevel, FraudIndicator, ThreatIntelMatch

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", ""))
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.5-flash")

FRAUD_ANALYSIS_PROMPT = """
You are ShieldScan AI, a semantic fraud-analysis component for Malaysian scam content.
You may identify suspicious language, impersonation cues, urgency, credential theft cues,
and visual phishing indicators. Do not claim access to live PDRM, BNM, MCMC, DNS, WHOIS,
reputation, or threat-intelligence databases. Those checks are performed by other ShieldScan
components when available.

Analyze the following {input_type} for fraud indicators:

INPUT: {content}

Respond ONLY with a valid JSON object (no markdown, no backticks) with this exact structure:
{{
  "threat_level": "SAFE|LOW|MEDIUM|HIGH|CRITICAL",
  "confidence_score": <0-100 integer>,
  "summary_en": "<2-3 short, plain-English sentences a normal person can understand>",
  "summary_bm": "<2-3 short, plain Bahasa Malaysia sentences a normal person can understand>",
  "indicators": [
    {{"category": "<category>", "description": "<plain-language explanation of what was found>", "severity": "low|medium|high"}}
  ],
  "recommendation_en": "<short, practical next step written directly for the user>",
  "recommendation_bm": "<short, practical next step written directly for the user in Bahasa Malaysia>"
}}

USER-FACING WRITING RULES:
- Write for a normal person, not a cybersecurity analyst.
- Say what the content appears to be and why it matters in simple language.
- Prefer concrete wording such as "This link uses a suspicious domain" over jargon such as "anomalous lexical indicators were detected".
- Do not repeat the same conclusion in multiple sentences.
- Avoid dramatic or alarmist wording unless the evidence is genuinely strong.
- For SAFE content, clearly say that no scam or phishing signs were found. Do not invent a warning just to sound cautious.
- For suspicious content, explain the practical concern and what the user should avoid doing.
- Recommendations should be actionable: e.g. "Don't click the link", "Don't enter your banking details", or "Verify this through the official website".
- Do not mention internal scores, prompts, models, pipelines, retrieval, or other ShieldScan implementation details in the summary or recommendation.

Threat Level Guidelines:
- SAFE: No fraud indicators found in the supplied content.
- LOW: Minor suspicious elements. Proceed with caution.
- MEDIUM: Multiple fraud signals. Verify before proceeding.
- HIGH: Strong fraud indicators. Do not proceed without independent verification.
- CRITICAL: Very strong fraud/credential-theft indicators in the supplied content.

The confidence score is your model confidence only. It is not a calibrated probability and
will be combined with deterministic evidence by ShieldScan's risk engine.
"""

GROUNDED_SYNTHESIS_PROMPT = """
You are ShieldScan AI's grounded report synthesizer.

The authoritative final risk level and risk score below were already computed by ShieldScan's
risk engine. You MUST NOT change, reinterpret, or contradict them. Your task is only to improve
the user-facing explanation using the supplied semantic analysis and retrieved threat-intelligence
records.

Rules:
- Write for a normal person, not a cybersecurity analyst.
- Use short, natural sentences and everyday language.
- Start by telling the user what the submitted item appears to be and the main reason for the result.
- Explain the most useful evidence instead of listing technical pipeline terminology.
- If retrieved intelligence is only related, say it is related guidance or a similar scam pattern, not proof that this exact item is fraudulent.
- Use only facts present in SEMANTIC ANALYSIS and RETRIEVED EVIDENCE.
- Treat retrieved records as related intelligence, not proof that the scanned item is identical.
- Never claim that an authority confirmed this specific user-submitted item unless the evidence says so.
- Do not invent agencies, dates, URLs, case IDs, victims, losses, or live-database checks.
- If evidence is weak or only broadly similar, say so clearly.
- Keep recommendations practical and conservative.
- Do not mention prompts, models, retrieval pipelines, JSON, scoring internals, or other implementation details.
- Do not use empty filler such as "it is important to be cautious" without saying what the user should actually do.
- For SAFE results, give the user a simple reassuring explanation without claiming absolute safety.
- For HIGH or CRITICAL results, lead with the safest action and make it unmistakable.
- Return JSON only.

AUTHORITATIVE RISK:
level={risk_level}
score={risk_score}

SEMANTIC ANALYSIS:
{semantic_analysis}

RETRIEVED EVIDENCE:
{retrieved_evidence}

Respond with exactly:
{{
  "summary_en": "<2-4 short, plain-English sentences explaining what was found and why>",
  "summary_bm": "<2-4 short, plain Bahasa Malaysia sentences explaining what was found and why>",
  "recommendation_en": "<one or two short, practical next steps for the user>",
  "recommendation_bm": "<one or two short, practical next steps for the user in Bahasa Malaysia>"
}}
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
                model=GEMINI_MODEL,
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
                    types.Part.from_text(text=prompt),
                ]
            )
        except Exception:
            response = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=prompt
            )
    else:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
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
            "summary_en": "We could not read the analysis reliably. Please verify this through an official source before taking action.",
            "summary_bm": "Kami tidak dapat membaca hasil analisis dengan pasti. Sila sahkan melalui sumber rasmi sebelum mengambil tindakan.",
            "indicators": [],
            "recommendation_en": "Verify this through an official channel before clicking, paying, or sharing personal information.",
            "recommendation_bm": "Sahkan melalui saluran rasmi sebelum klik, membuat bayaran, atau berkongsi maklumat peribadi."
        }

    duration_ms = int((time.time() - start) * 1000)
    threat_level = _parse_threat_level(data.get("threat_level", "MEDIUM"))
    confidence_score = _clamp_int(data.get("confidence_score", 50), 0, 100)

    return ScanResult(
        threat_level=threat_level,
        confidence_score=confidence_score,
        summary_en=data.get("summary_en", ""),
        summary_bm=data.get("summary_bm", ""),
        indicators=_parse_indicators(data.get("indicators", [])),
        recommendation_en=data.get("recommendation_en", ""),
        recommendation_bm=data.get("recommendation_bm", ""),
        rag_matches=[],
        scan_duration_ms=duration_ms
    )


def synthesize_grounded_report(result: ScanResult, matches: list[ThreatIntelMatch]) -> ScanResult:
    """Use retrieved evidence to improve explanation without changing authoritative risk.

    This is the generation half of ShieldScan's RAG pipeline. Retrieval evidence can shape
    summaries and recommendations, but deterministic risk-engine outputs remain locked.
    Failures are non-fatal: the original semantic report is returned unchanged.
    """
    if not matches:
        return result

    semantic_analysis = {
        "summary_en": result.summary_en,
        "summary_bm": result.summary_bm,
        "indicators": [item.model_dump(mode="json") for item in result.indicators],
        "recommendation_en": result.recommendation_en,
        "recommendation_bm": result.recommendation_bm,
    }
    retrieved_evidence = [
        {
            "id": match.id,
            "title": match.title,
            "category": match.category,
            "source_name": match.source_name,
            "source_url": match.source_url,
            "matched_terms": match.matched_terms,
            "summary": match.summary,
            "retrieval_method": match.retrieval_method,
        }
        for match in matches
    ]

    prompt = GROUNDED_SYNTHESIS_PROMPT.format(
        risk_level=result.threat_level.value,
        risk_score=result.confidence_score,
        semantic_analysis=json.dumps(semantic_analysis, ensure_ascii=False),
        retrieved_evidence=json.dumps(retrieved_evidence, ensure_ascii=False),
    )

    try:
        response = client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        raw = re.sub(r"```json|```", "", response.text.strip()).strip()
        data = json.loads(raw)
    except Exception:
        return result

    # Intentionally update only narrative fields. Risk level, score, evidence and
    # indicators remain authoritative outputs from earlier pipeline stages.
    result.summary_en = str(data.get("summary_en") or result.summary_en)
    result.summary_bm = str(data.get("summary_bm") or result.summary_bm)
    result.recommendation_en = str(data.get("recommendation_en") or result.recommendation_en)
    result.recommendation_bm = str(data.get("recommendation_bm") or result.recommendation_bm)
    return result


def _parse_threat_level(value: object) -> ThreatLevel:
    try:
        return ThreatLevel(str(value).upper())
    except ValueError:
        return ThreatLevel.MEDIUM


def _clamp_int(value: object, minimum: int, maximum: int) -> int:
    try:
        number = int(value)
    except (TypeError, ValueError):
        number = minimum
    return max(minimum, min(number, maximum))


def _parse_indicators(value: object) -> list[FraudIndicator]:
    if not isinstance(value, list):
        return []

    indicators: list[FraudIndicator] = []
    for item in value:
        if not isinstance(item, dict):
            continue
        try:
            indicators.append(FraudIndicator(**item))
        except Exception:
            continue
    return indicators
