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
      expect(result.ragMatches, isEmpty);
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
        'label': 'Gemini analysis complete',
        'duration_ms': 1234,
      });

      expect(provider.agentSteps[1].status, 'done');
      expect(provider.agentSteps[1].label, 'Gemini analysis complete');
      expect(provider.agentSteps[1].durationMs, 1234);
    });

    test('stores SSE errors as user visible state', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({
        'type': 'error',
        'message': 'Analysis failed',
      });

      expect(provider.status, ScanStatus.error);
      expect(provider.errorMessage, 'Analysis failed');
    });

    test('done event does not overwrite an error state', () {
      final provider = ScanProvider();
      provider.beginScanSessionForTest();

      provider.handleSseEvent({
        'type': 'error',
        'message': 'Analysis failed',
      });
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
        'confidence_score': 91,
        'summary_en': 'High risk.',
        'summary_bm': 'Risiko tinggi.',
        'indicators': [],
        'recommendation_en': 'Do not proceed.',
        'recommendation_bm': 'Jangan teruskan.',
        'rag_matches': [],
        'scan_duration_ms': 1400,
      });

      expect(provider.status, ScanStatus.done);
      expect(provider.totalScansToday, previousScans + 1);
      expect(provider.threatsBlocked, previousThreats + 1);
    });
  });
}
