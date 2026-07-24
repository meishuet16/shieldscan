import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

enum ThreatLevel { safe, low, medium, high, critical }

enum ScanStatus { idle, scanning, done, error }

class AgentStep {
  final int step;
  String label;
  String status;
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

  factory FraudIndicator.fromJson(Map<String, dynamic> json) {
    return FraudIndicator(
      category: json['category']?.toString() ?? 'Signal',
      description: json['description']?.toString() ?? '',
      severity: json['severity']?.toString().toLowerCase() ?? 'low',
    );
  }
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
    final level = json['threat_level']?.toString().toLowerCase();
    final levelMap = {
      'safe': ThreatLevel.safe,
      'low': ThreatLevel.low,
      'medium': ThreatLevel.medium,
      'high': ThreatLevel.high,
      'critical': ThreatLevel.critical,
    };
    final indicators = json['indicators'];
    final ragMatches = json['rag_matches'];

    return ScanResult(
      threatLevel: levelMap[level] ?? ThreatLevel.medium,
      confidenceScore: _asInt(json['confidence_score']).clamp(0, 100).toInt(),
      summaryEn: json['summary_en']?.toString() ?? '',
      summaryBm: json['summary_bm']?.toString() ?? '',
      indicators: indicators is List
          ? indicators
              .whereType<Map>()
              .map((item) => FraudIndicator.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : <FraudIndicator>[],
      recommendationEn: json['recommendation_en']?.toString() ?? '',
      recommendationBm: json['recommendation_bm']?.toString() ?? '',
      ragMatches: ragMatches is List
          ? ragMatches.map((item) => item.toString()).toList()
          : <String>[],
      scanDurationMs: _asInt(json['scan_duration_ms']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ScanProvider extends ChangeNotifier {
  ScanStatus status = ScanStatus.idle;
  List<AgentStep> agentSteps = [];
  ScanResult? result;
  String? errorMessage;
  int totalScansToday = 1247;
  int threatsBlocked = 89;

  void reset() {
    status = ScanStatus.idle;
    agentSteps = [];
    result = null;
    errorMessage = null;
    notifyListeners();
  }

  @visibleForTesting
  void beginScanSessionForTest() {
    _beginScanSession();
  }

  Future<void> scan({
    required String type,
    required String content,
  }) async {
    _beginScanSession();

    final client = http.Client();
    try {
      final uri = Uri.parse('$_apiBase/api/scan/stream');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'type': type, 'content': content});

      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw HttpException(
          'Scan request failed (${response.statusCode})'
          '${body.isNotEmpty ? ': $body' : ''}',
        );
      }

      final stream =
          response.stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in stream) {
        if (!line.startsWith('data: ')) continue;

        final jsonStr = line.substring(6);
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          handleSseEvent(data);
        } catch (_) {
          continue;
        }
      }
    } catch (error) {
      status = ScanStatus.error;
      errorMessage = error is HttpException
          ? error.message
          : 'Connection error: ${error.toString()}. Make sure the backend is running.';
      _markRunningStepAsError();
      notifyListeners();
    } finally {
      client.close();
    }
  }

  void handleSseEvent(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    if (type == 'step') {
      final stepNum = ScanResult._asInt(data['step']);
      final idx = stepNum - 1;
      if (idx >= 0 && idx < agentSteps.length) {
        agentSteps[idx].label = data['label']?.toString() ?? agentSteps[idx].label;
        agentSteps[idx].status = data['status']?.toString() ?? 'done';
        final duration = data['duration_ms'];
        agentSteps[idx].durationMs = duration == null ? null : ScanResult._asInt(duration);
      }
    } else if (type == 'result') {
      result = ScanResult.fromJson(data);
      totalScansToday++;
      if (result!.threatLevel == ThreatLevel.high ||
          result!.threatLevel == ThreatLevel.critical) {
        threatsBlocked++;
      }
      status = ScanStatus.done;
    } else if (type == 'error') {
      status = ScanStatus.error;
      errorMessage = data['message']?.toString() ?? 'Analysis failed.';
      _markRunningStepAsError();
    } else if (type == 'done' && status == ScanStatus.scanning) {
      status = ScanStatus.done;
    }

    notifyListeners();
  }

  void _beginScanSession() {
    status = ScanStatus.scanning;
    result = null;
    errorMessage = null;
    agentSteps = [
      AgentStep(step: 1, label: 'Classifying input type', status: 'pending'),
      AgentStep(
        step: 2,
        label: 'Gemini 2.5 Flash multimodal analysis',
        status: 'pending',
      ),
      AgentStep(
        step: 3,
        label: 'Cross-referencing PDRM/BNM/MCMC database',
        status: 'pending',
      ),
      AgentStep(
        step: 4,
        label: 'Generating bilingual threat report',
        status: 'pending',
      ),
    ];
    notifyListeners();
  }

  void _markRunningStepAsError() {
    for (final step in agentSteps) {
      if (step.status == 'running') {
        step.status = 'error';
        return;
      }
    }
  }
}

class HttpException implements Exception {
  final String message;

  const HttpException(this.message);

  @override
  String toString() => message;
}
