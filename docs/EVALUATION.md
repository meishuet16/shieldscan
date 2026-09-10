# ShieldScan Evaluation and Calibration

ShieldScan should not treat model confidence, lexical URL signals, network metadata, keyword overlap, or vector similarity as calibrated probabilities. This document separates stable regression checks from thresholds that still need empirical calibration.

## Stable regression suite

`backend/evaluation/fixtures.json` contains deterministic cases that run in CI without calling Gemini.

Current coverage includes:
- official Malaysian banking URLs that must not trigger brand impersonation;
- obvious banking lookalike URLs that must trigger brand impersonation and a high deterministic URL score;
- IP-host credential bait and insecure HTTP signals;
- sourced phishing and investment-pattern retrieval;
- benign everyday text and benign banking discussion that must not produce local threat-intelligence matches;
- response guidance such as NSRC 997 instructions that must never appear as threat-pattern evidence.

Additional unit tests cover image retrieval-query construction. They verify that raw base64 never enters the retrieval layer, semantic summaries/indicators are used instead, duplicate text is removed, and query length is bounded.

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

The purpose of this floor is to prevent LanceDB from returning a nearest neighbour merely because every query has a nearest neighbour. The value is provisional and should be tuned against a larger labelled retrieval set.

### Local keyword fallback

`SHIELDSCAN_LOCAL_KEYWORD_MIN_SCORE` defaults to `0.20`.

The threshold was introduced after the labelled benign banking-discussion fixture exposed a generic `bank + login` false positive at `0.1818`. It is still provisional and should be recalibrated against a larger benign/malicious text set rather than treated as a universal optimum.

### Network evidence

DNS/TLS/RDAP network evidence is supplementary and capped to at most 25 additional deterministic points. Valid TLS/public DNS does not reduce risk. Current young-domain and TLS-failure weights are engineering defaults and require calibration.

## Image retrieval evaluation gap

Image scans now retrieve threat intelligence from Gemini-produced semantic summaries and fraud-indicator descriptions rather than raw image bytes. The plumbing is covered by deterministic unit tests, but retrieval quality itself is not yet measured because it depends on model-extracted text.

Before claiming image-RAG quality, build a labelled screenshot set covering phishing SMS, fake bank login screens, investment ads, job scams, benign banking screenshots, and ambiguous content. Evaluate both semantic extraction quality and downstream retrieval precision/recall.

## Next calibration work

Before production claims are made, build a larger labelled set with at least:
- phishing / credential theft;
- bank and government impersonation;
- investment scams and clone entities;
- job scams and mule-account recruitment;
- malicious-app lures;
- benign financial conversations;
- benign URLs with words such as login, verify, bank, support and investment;
- screenshot equivalents of malicious, benign and ambiguous cases;
- ambiguous cases where the correct result should be verification rather than a confident fraud verdict.

Measure at minimum:
- false-positive rate for benign cases;
- false-negative rate for clearly malicious cases;
- retrieval precision@k and recall@k;
- risk-band confusion matrix;
- behaviour by English and Bahasa Malaysia wording;
- image semantic-extraction-to-retrieval accuracy;
- behaviour before and after corpus refreshes.

Any threshold change should update both this document and the labelled evaluation results. A threshold should not be changed merely to make a single anecdotal example pass.
