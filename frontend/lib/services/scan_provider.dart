import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Read API base URL injected at build time (Cloud Run URL)
const String _apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

enum ThreatLevel { safe, low, medium, high, critical }

enum ScanStatus { idle, scanning, done, error }

class AgentStep {
  final int step;
  String label;
  String status; // running | done | error
  int? durationMs;

  AgentStep({
    required this.step,
    required this.label,
    required this.status,
    this.durationMs,
  });
}

class FraudIndicator {
  final String category;
  final String description;
  final String severity;

  FraudIndicator({
    required this.category,
    required this.description,
    required this.severity,
  });

  factory FraudIndicator.fromJson(Map<String, dynamic> json) => FraudIndicator(
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        severity: json['severity'] ?? 'low',
      );
}

class ScanResult {
  final ThreatLevel threatLevel;
  final int confidenceScore;
  final String summaryEn;
  final String summaryBm;
  final List<FraudIndicator> indicators;
  final String recommendationEn;
  final String recommendationBm;
  final List<String> ragMatches;
  final int scanDurationMs;

  ScanResult({
    required this.threatLevel,
    required this.confidenceScore,
    required this.summaryEn,
    required this.summaryBm,
    required this.indicators,
    required this.recommendationEn,
    required this.recommendationBm,
    required this.ragMatches,
    required this.scanDurationMs,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final levelStr = (json['threat_level'] as String).toLowerCase();
    final levelMap = {
      'safe': ThreatLevel.safe,
      'low': ThreatLevel.low,
      'medium': ThreatLevel.medium,
      'high': ThreatLevel.high,
      'critical': ThreatLevel.critical,
    };
    return ScanResult(
      threatLevel: levelMap[levelStr] ?? ThreatLevel.medium,
      confidenceScore: json['confidence_score'] ?? 0,
      summaryEn: json['summary_en'] ?? '',
      summaryBm: json['summary_bm'] ?? '',
      indicators: (json['indicators'] as List<dynamic>? ?? [])
          .map((i) => FraudIndicator.fromJson(i as Map<String, dynamic>))
          .toList(),
      recommendationEn: json['recommendation_en'] ?? '',
      recommendationBm: json['recommendation_bm'] ?? '',
      ragMatches: List<String>.from(json['rag_matches'] ?? []),
      scanDurationMs: json['scan_duration_ms'] ?? 0,
    );
  }
}

class ScanProvider extends ChangeNotifier {
  ScanStatus status = ScanStatus.idle;
  List<AgentStep> agentSteps = [];
  ScanResult? result;
  String? errorMessage;
  int totalScansToday = 1247; // Mock stat
  int threatsBlocked = 89;

  void reset() {
    status = ScanStatus.idle;
    agentSteps = [];
    result = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> scan({
    required String type,
    required String content,
  }) async {
    reset();
    status = ScanStatus.scanning;
    agentSteps = [
      AgentStep(step: 1, label: 'Classifying input type', status: 'pending'),
      AgentStep(step: 2, label: 'Gemini 1.5 Pro multimodal analysis', status: 'pending'),
      AgentStep(step: 3, label: 'Cross-referencing PDRM/BNM/MCMC database', status: 'pending'),
      AgentStep(step: 4, label: 'Generating bilingual threat report', status: 'pending'),
    ];
    notifyListeners();

    try {
      final uri = Uri.parse('$_apiBase/api/scan/stream');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'type': type, 'content': content});

      final response = await http.Client().send(request);
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            _handleSSEEvent(data);
          } catch (_) {}
        }
      }
    } catch (e) {
      status = ScanStatus.error;
      errorMessage = 'Connection error: ${e.toString()}. Make sure the backend is running.';
      notifyListeners();
    }
  }

  void _handleSSEEvent(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (type == 'step') {
      final stepNum = data['step'] as int;
      final idx = stepNum - 1;
      if (idx >= 0 && idx < agentSteps.length) {
        agentSteps[idx].label = data['label'] ?? agentSteps[idx].label;
        agentSteps[idx].status = data['status'] ?? 'done';
        agentSteps[idx].durationMs = data['duration_ms'] as int?;
      }
    } else if (type == 'result') {
      result = ScanResult.fromJson(data);
      totalScansToday++;
      if (result!.threatLevel == ThreatLevel.high ||
          result!.threatLevel == ThreatLevel.critical) {
        threatsBlocked++;
      }
      status = ScanStatus.done;
    } else if (type == 'done') {
      if (status != ScanStatus.done) {
        status = ScanStatus.done;
      }
    }

    notifyListeners();
  }
}
