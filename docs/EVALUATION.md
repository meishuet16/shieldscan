# ShieldScan Evaluation and Calibration

ShieldScan should not treat model confidence, lexical URL signals, or vector similarity as calibrated probabilities. This document separates stable regression checks from thresholds that still need empirical calibration.

## Stable regression suite

`backend/evaluation/fixtures.json` contains deterministic cases that run in CI without calling Gemini.

Current coverage includes:
- official Malaysian banking URLs that must not trigger brand impersonation;
- obvious banking lookalike URLs that must trigger brand impersonation and a high deterministic URL score;
- IP-host credential bait and insecure HTTP signals;
- sourced phishing and investment-pattern retrieval;
- benign everyday text and benign banking discussion that must not produce local threat-intelligence matches;
- response guidance such as NSRC 997 instructions that must never appear as threat-pattern evidence.

The regression suite is intentionally deterministic. Gemini outputs are not asserted in ordinary CI because generative model responses can vary between runs and model revisions.

## Thresholds currently treated as provisional

### Risk levels

Current `shieldscan-v2.1` score bands:
- SAFE: 0-19
- LOW: 20-39
- MEDIUM: 40-64
- HIGH: 65-84
- CRITICAL: 85-100

These are engineering defaults, not validated fraud probabilities.

### Semantic retrieval

`SHIELDSCAN_SEMANTIC_MIN_SIMILARITY` defaults to `0.35`.

The purpose of this floor is to prevent LanceDB from returning a nearest neighbour merely because every query has a nearest neighbour. The value is provisional and should be tuned against a larger labelled retrieval set.

## Next calibration work

Before production claims are made, build a larger labelled set with at least:
- phishing / credential theft;
- bank and government impersonation;
- investment scams and clone entities;
- job scams and mule-account recruitment;
- malicious-app lures;
- benign financial conversations;
- benign URLs with words such as login, verify, bank, support and investment;
- ambiguous cases where the correct result should be verification rather than a confident fraud verdict.

Measure at minimum:
- false-positive rate for benign cases;
- false-negative rate for clearly malicious cases;
- retrieval precision@k and recall@k;
- risk-band confusion matrix;
- behaviour by English and Bahasa Malaysia wording;
- behaviour before and after corpus refreshes.

Any threshold change should update both this document and the labelled evaluation results. A threshold should not be changed merely to make a single anecdotal example pass.
