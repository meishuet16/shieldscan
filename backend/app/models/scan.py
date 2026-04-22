from pydantic import BaseModel
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


class ScanResult(BaseModel):
    threat_level: ThreatLevel
    confidence_score: int  # 0-100
    summary_en: str
    summary_bm: str
    indicators: List[FraudIndicator]
    recommendation_en: str
    recommendation_bm: str
    rag_matches: Optional[List[str]] = []
    scan_duration_ms: int


class AgentStep(BaseModel):
    step: int
    label: str
    status: str  # "running" | "done" | "error"
    duration_ms: Optional[int] = None
