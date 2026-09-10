import 'package:flutter_test/flutter_test.dart';
import 'package:shieldscan/services/scan_provider.dart';

void main() {
  group('ScanResult.fromJson', () {
    test('falls back to medium when threat level is unknown', () {
      final result = ScanResult.fromJson({
        'threat_level': 'unexpected',
        'confidence_score': 71,
        'summary_en': 'Review needed.',
        'summary_bm': 'Semakan diperlukan.',
        'recommendation_en': 'Verify through official channels.',
        'recommendation_bm': 'Sahkan melalui saluran rasmi.',
      });

      expect(result.threatLevel, ThreatLevel.medium);
      expect(result.indicators, isEmpty);
      expect(result.riskEvidence, isEmpty);
      expect(result.ragMatches, isEmpty);
    });

    test('prefers explicit risk and threat intelligence fields over legacy aliases', () {
      final result = ScanResult.fromJson({
        'threat_level': 'HIGH',
        'risk_score': 82,
        'confidence_score': 12,
        'summary_en': 'Review needed.',
        'summary_bm': 'Semakan diperlukan.',
        'recommendation_en': 'Verify through official channels.',
        'recommendation_bm': 'Sahkan melalui saluran rasmi.',
        'threat_intel_matches': [
          {
            'id': 'BNM-NEW',
            'title': 'Primary field record',
            'category': 'phishing',
            'source_name': 'Bank Negara Malaysia',
            'matched_terms': ['login'],
            'summary': 'Primary threat intelligence field.',
            'retrieval_method': 'local-keyword-v3',
            'evidence_role': 'threat_pattern',
          }
        ],
        'rag_matches': [
          {
            'id': 'LEGACY-OLD',
            'title': 'Legacy field record',
            'category': 'legacy',
            'source_name': 'Legacy source',
            'matched_terms': [],
            'summary': 'Should not win when primary field exists.',
            'retrieval_method': 'legacy',
            'evidence_role': 'threat_pattern',
          }
        ],
        'scan_duration_ms': 100,
      });

      expect(result.riskScore, 82);
      expect(result.confidenceScore, 82);
      expect(result.threatIntelMatches.single.id, 'BNM-NEW');
      expect(result.ragMatches.single.id, 'BNM-NEW');
    });

    test('parses deterministic and provenance-bearing evidence', () {
      final result = ScanResult.fromJson({
        'threat_level': 'HIGH',
        'confidence_score': 78,
        'ai_confidence_score': 61,
        'deterministic_score': 70,
        'scoring_version': 'shieldscan-v2.2',
        'summary_en': 'Review needed.',
        'summary_bm': 'Semakan diperlukan.',
        'indicators': [],
        'risk_evidence': [
          {
            'source': 'url_intelligence',
            'code': 'brand_impersonation',
            'label': 'Possible brand impersonation',
            'score': 35,
            'evidence': 'maybank2u-secure-login.xyz',
          },
          {
            'source': 'network_intelligence',
            'code': 'tls_valid',
            'label': 'TLS certificate validated',
            'score': 0,
            'evidence': 'TLS validated via 203.0.113.10',
          }
        ],
        'recommendation_en': 'Verify through official channels.',
        'recommendation_bm': 'Sahkan melalui saluran rasmi.',
        'rag_matches': [
          {
            'id': 'BNM-PHISHING-GUIDANCE',
            'title': 'Phishing guidance',
            'category': 'phishing',
            'source_name': 'Bank Negara Malaysia — Financial Fraud Alerts',
            'source_url': 'https://www.bnm.gov.my/financial-fraud-alerts',
            'matched_terms': ['login'],
            'summary': 'Lookalike websites may steal banking credentials.',
            'retrieval_method': 'lancedb-semantic-v2',
            'evidence_role': 'threat_pattern',
            'retrieval_score': 0.72,
            'published_at': '2026-08-03',
            'agency': 'BNM',
          }
        ],
        'scan_duration_ms': 1200,
      });

      expect(result.confidenceScore, 78);
      expect(result.riskScore, 78);
      expect(result.aiConfidenceScore, 61);
      expect(result.deterministicScore, 70);
      expect(result.scoringVersion, 'shieldscan-v2.2');
      expect(result.riskEvidence.first.code, 'brand_impersonation');
      expect(result.riskEvidence.last.code, 'tls_valid');
      expect(result.ragMatches.single.id, 'BNM-PHISHING-GUIDANCE');
      expect(result.ragMatches.single.sourceName, startsWith('Bank Negara Malaysia'));
      expect(result.ragMatches.single.evidenceRole, 'threat_pattern');
      expect(result.ragMatches.single.retrievalScore, closeTo(0.72, 0.001));
      expect(result.ragMatches.single.publishedAt, '2026-08-03');
      expect(result.ragMatches.single.agency, 'BNM');
    });
  });

  group('ScanProvider.handleSseEvent', () {
    test('updates pipeline step labels and durations', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({
        'type': 'step',
        'step': 2,
        'status': 'done',
        'label': 'Semantic analysis complete',
        'duration_ms': 1234,
      });

      expect(provider.agentSteps[1].status, 'done');
      expect(provider.agentSteps[1].label, 'Semantic analysis complete');
      expect(provider.agentSteps[1].durationMs, 1234);
    });

    test('stores SSE errors as user visible state', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({'type': 'error', 'message': 'Analysis failed'});

      expect(provider.status, ScanStatus.error);
      expect(provider.errorMessage, 'Analysis failed');
    });

    test('done event does not overwrite an error state', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({'type': 'error', 'message': 'Analysis failed'});
      provider.handleSseEvent({'type': 'done'});

      expect(provider.status, ScanStatus.error);
      expect(provider.errorMessage, 'Analysis failed');
    });

    test('result event increments threat counters for high risk results', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();
      final previousScans = provider.totalScansToday;
      final previousThreats = provider.threatsBlocked;

      provider.handleSseEvent({
        'type': 'result',
        'threat_level': 'HIGH',
        'risk_score': 91,
        'confidence_score': 91,
        'summary_en': 'High risk.',
        'summary_bm': 'Risiko tinggi.',
        'indicators': [],
        'risk_evidence': [],
        'recommendation_en': 'Do not proceed.',
        'recommendation_bm': 'Jangan teruskan.',
        'threat_intel_matches': [],
        'rag_matches': [],
        'scan_duration_ms': 1400,
      });

      expect(provider.status, ScanStatus.done);
      expect(provider.totalScansToday, previousScans + 1);
      expect(provider.threatsBlocked, previousThreats + 1);
    });
  });
}
