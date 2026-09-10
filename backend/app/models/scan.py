from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum


class InputType(str, Enum):
    URL = "url"
    TEXT = "text"
    IMAGE = "image"


class ThreatLevel(str, Enum):
    SAFE = "SAFE"
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class ScanRequest(BaseModel):
    type: InputType
    content: str  # URL string, text content, or base64 image


class FraudIndicator(BaseModel):
    category: str
    description: str
    severity: str


class RiskEvidence(BaseModel):
    source: str
    code: str
    label: str
    score: int
    evidence: str


class ThreatIntelMatch(BaseModel):
    id: str
    title: str
    category: str
    source_name: str
    source_url: Optional[str] = None
    matched_terms: List[str] = Field(default_factory=list)
    summary: str
    retrieval_method: str


class ScanResult(BaseModel):
    threat_level: ThreatLevel
    confidence_score: int  # final evidence-based risk score, 0-100
    summary_en: str
    summary_bm: str
    indicators: List[FraudIndicator]
    recommendation_en: str
    recommendation_bm: str
    rag_matches: Optional[List[ThreatIntelMatch]] = Field(default_factory=list)
    scan_duration_ms: int
    ai_confidence_score: Optional[int] = None
    deterministic_score: int = 0
    risk_evidence: List[RiskEvidence] = Field(default_factory=list)
    scoring_version: str = "shieldscan-v2"


class AgentStep(BaseModel):
    step: int
    label: str
    status: str  # "running" | "done" | "error"
    duration_ms: Optional[int] = None
