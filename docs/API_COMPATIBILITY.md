# API response compatibility

ShieldScan is migrating two hackathon-era response names to clearer production names without breaking existing clients.

## Risk score

Primary field:

```json
"risk_score": 78
```

Legacy compatibility field:

```json
"confidence_score": 78
```

`confidence_score` historically contained the final ShieldScan risk score even though its name implied model confidence. New clients should use `risk_score`.

Gemini's separate self-reported confidence remains available as:

```json
"ai_confidence_score": 61
```

The backend keeps `risk_score` and `confidence_score` synchronized during risk-engine and network-intelligence updates.

## Threat intelligence matches

Primary field:

```json
"threat_intel_matches": []
```

Legacy compatibility field:

```json
"rag_matches": []
```

New clients should use `threat_intel_matches`. The legacy field is retained temporarily for older frontend/API consumers.

The backend keeps both lists synchronized after retrieval and grounded synthesis. The Flutter client prefers the new fields and falls back to the legacy names when talking to an older backend.

## Removal policy

The legacy fields should not be removed until deployed clients have migrated and a deliberate API-versioning/deprecation decision is made. They are compatibility aliases, not independent values.
