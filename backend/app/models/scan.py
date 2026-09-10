from pydantic import BaseModel, Field, model_validator
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
    evidence_role: str = "threat_pattern"
    retrieval_score: Optional[float] = None
    published_at: Optional[str] = None
    agency: Optional[str] = None


class ScanResult(BaseModel):
    threat_level: ThreatLevel

    # Primary public name. `confidence_score` is retained temporarily for clients built
    # against the hackathon-era API where this field actually meant risk, not confidence.
    risk_score: Optional[int] = None
    confidence_score: int

    summary_en: str
    summary_bm: str
    indicators: List[FraudIndicator]
    recommendation_en: str
    recommendation_bm: str

    # Primary public name plus backwards-compatible legacy alias.
    threat_intel_matches: Optional[List[ThreatIntelMatch]] = Field(default_factory=list)
    rag_matches: Optional[List[ThreatIntelMatch]] = Field(default_factory=list)

    scan_duration_ms: int
    ai_confidence_score: Optional[int] = None
    deterministic_score: int = 0
    risk_evidence: List[RiskEvidence] = Field(default_factory=list)
    scoring_version: str = "shieldscan-v2"

    @model_validator(mode="after")
    def sync_compatibility_fields(self):
        """Keep new explicit names and legacy response fields consistent during migration."""
        if self.risk_score is None:
            self.risk_score = self.confidence_score
        else:
            self.confidence_score = self.risk_score

        primary_matches = list(self.threat_intel_matches or [])
        legacy_matches = list(self.rag_matches or [])
        if primary_matches:
            self.rag_matches = primary_matches
        elif legacy_matches:
            self.threat_intel_matches = legacy_matches
        else:
            self.threat_intel_matches = []
            self.rag_matches = []
        return self


class AgentStep(BaseModel):
    step: int
    label: str
    status: str  # "running" | "done" | "error"
    duration_ms: Optional[int] = None
