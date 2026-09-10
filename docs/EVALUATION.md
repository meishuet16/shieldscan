# ShieldScan Evaluation and Calibration

ShieldScan should not treat model confidence, lexical URL signals, vector similarity, or network metadata as calibrated probabilities. This document separates stable regression checks from thresholds that still need empirical calibration.

## Stable regression suite

`backend/evaluation/fixtures.json` contains deterministic cases that run in CI without calling Gemini.

Current coverage includes:
- official Malaysian banking URLs that must not trigger brand impersonation;
- obvious banking lookalike URLs that must trigger brand impersonation;
- IP-host credential bait and insecure HTTP signals;
- sourced phishing and investment-pattern retrieval;
- benign everyday text and benign banking discussion that must not produce local threat-intelligence matches;
- response guidance such as NSRC 997 instructions that must never appear as threat-pattern evidence.

The regression suite is intentionally deterministic. Gemini outputs are not asserted in ordinary CI because generative model responses can vary between runs and model revisions.

## Thresholds currently treated as provisional

### Risk levels

Current `shieldscan-v2.2` score bands:
- SAFE: 0-19
- LOW: 20-39
- MEDIUM: 40-64
- HIGH: 65-84
- CRITICAL: 85-100

These are engineering defaults, not validated fraud probabilities.

### Semantic retrieval

`SHIELDSCAN_SEMANTIC_MIN_SIMILARITY` defaults to `0.35`.

The purpose of this floor is to prevent LanceDB from returning a nearest neighbour merely because every query has a nearest neighbour.

### Local keyword fallback

`SHIELDSCAN_LOCAL_KEYWORD_MIN_SCORE` defaults to `0.20`.

This floor was introduced after a labelled benign fixture (a normal banking mobile-app/login UX discussion) produced a false-positive phishing match at `0.1818`. The threshold remains provisional and should be tuned against a larger labelled set rather than one anecdotal example.

### Network intelligence

DNS/TLS/RDAP evidence is supplementary. Positive infrastructure metadata such as valid TLS and public DNS has zero negative-risk weight because scam sites can also use HTTPS and normal hosting.

Risk-bearing network metadata is capped at 25 additional deterministic points per scan. Before changing these weights, evaluate newly registered legitimate domains, young phishing/lookalike domains, long-lived compromised domains, TLS-valid scam sites, RDAP-missing cases, and provider failures.

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
- DNS/TLS/RDAP coverage and failure rate;
- score impact distribution by network signal;
- behaviour by English and Bahasa Malaysia wording;
- behaviour before and after corpus refreshes.

Any threshold change should update both this document and the labelled evaluation results. A threshold should not be changed merely to make a single anecdotal example pass.
