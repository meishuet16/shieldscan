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

  AgentStep({required this.step, required this.label, required this.status, this.durationMs});
}

class FraudIndicator {
  final String category;
  final String description;
  final String severity;

  FraudIndicator({required this.category, required this.description, required this.severity});

  factory FraudIndicator.fromJson(Map<String, dynamic> json) {
    return FraudIndicator(
      category: json['category']?.toString() ?? 'Signal',
      description: json['description']?.toString() ?? '',
      severity: json['severity']?.toString().toLowerCase() ?? 'low',
    );
  }
}

class RiskEvidence {
  final String source;
  final String code;
  final String label;
  final int score;
  final String evidence;

  RiskEvidence({
    required this.source,
    required this.code,
    required this.label,
    required this.score,
    required this.evidence,
  });

  factory RiskEvidence.fromJson(Map<String, dynamic> json) {
    return RiskEvidence(
      source: json['source']?.toString() ?? 'risk_engine',
      code: json['code']?.toString() ?? 'signal',
      label: json['label']?.toString() ?? 'Security signal',
      score: ScanResult._asInt(json['score']),
      evidence: json['evidence']?.toString() ?? '',
    );
  }
}

class ThreatIntelMatch {
  final String id;
  final String title;
  final String category;
  final String sourceName;
  final String? sourceUrl;
  final List<String> matchedTerms;
  final String summary;
  final String retrievalMethod;
  final String evidenceRole;
  final double? retrievalScore;
  final String? publishedAt;
  final String? agency;

  ThreatIntelMatch({
    required this.id,
    required this.title,
    required this.category,
    required this.sourceName,
    required this.sourceUrl,
    required this.matchedTerms,
    required this.summary,
    required this.retrievalMethod,
    required this.evidenceRole,
    required this.retrievalScore,
    required this.publishedAt,
    required this.agency,
  });

  factory ThreatIntelMatch.fromJson(Map<String, dynamic> json) {
    final terms = json['matched_terms'];
    return ThreatIntelMatch(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Related threat intelligence',
      category: json['category']?.toString() ?? 'fraud-intelligence',
      sourceName: json['source_name']?.toString() ?? 'Official source',
      sourceUrl: json['source_url']?.toString(),
      matchedTerms: terms is List ? terms.map((item) => item.toString()).toList() : <String>[],
      summary: json['summary']?.toString() ?? '',
      retrievalMethod: json['retrieval_method']?.toString() ?? 'retrieval',
      evidenceRole: json['evidence_role']?.toString() ?? 'threat_pattern',
      retrievalScore: _asDouble(json['retrieval_score']),
      publishedAt: json['published_at']?.toString(),
      agency: json['agency']?.toString(),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ScanResult {
  final ThreatLevel threatLevel;
  final int confidenceScore;
  final int? aiConfidenceScore;
  final int deterministicScore;
  final String scoringVersion;
  final String summaryEn;
  final String summaryBm;
  final List<FraudIndicator> indicators;
  final List<RiskEvidence> riskEvidence;
  final String recommendationEn;
  final String recommendationBm;
  final List<ThreatIntelMatch> ragMatches;
  final int scanDurationMs;

  ScanResult({
    required this.threatLevel,
    required this.confidenceScore,
    required this.aiConfidenceScore,
    required this.deterministicScore,
    required this.scoringVersion,
    required this.summaryEn,
    required this.summaryBm,
    required this.indicators,
    required this.riskEvidence,
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
    final riskEvidence = json['risk_evidence'];
    final ragMatches = json['rag_matches'];

    return ScanResult(
      threatLevel: levelMap[level] ?? ThreatLevel.medium,
      confidenceScore: _asInt(json['confidence_score']).clamp(0, 100).toInt(),
      aiConfidenceScore: json['ai_confidence_score'] == null
          ? null
          : _asInt(json['ai_confidence_score']).clamp(0, 100).toInt(),
      deterministicScore: _asInt(json['deterministic_score']).clamp(0, 100).toInt(),
      scoringVersion: json['scoring_version']?.toString() ?? 'shieldscan-v2',
      summaryEn: json['summary_en']?.toString() ?? '',
      summaryBm: json['summary_bm']?.toString() ?? '',
      indicators: indicators is List
          ? indicators
              .whereType<Map>()
              .map((item) => FraudIndicator.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <FraudIndicator>[],
      riskEvidence: riskEvidence is List
          ? riskEvidence
              .whereType<Map>()
              .map((item) => RiskEvidence.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <RiskEvidence>[],
      recommendationEn: json['recommendation_en']?.toString() ?? '',
      recommendationBm: json['recommendation_bm']?.toString() ?? '',
      ragMatches: ragMatches is List
          ? ragMatches
              .whereType<Map>()
              .map((item) => ThreatIntelMatch.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <ThreatIntelMatch>[],
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

  Future<void> scan({required String type, required String content}) async {
    _beginScanSession();

    final client = http.Client();
    try {
      final uri = Uri.parse('$_apiBase/api/scan/stream');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'type': type, 'content': content});

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Scan failed (${response.statusCode}): $body');
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final eventBlock = buffer.substring(0, index);
          buffer = buffer.substring(index + 2);
          _parseSseBlock(eventBlock);
        }
      }
    } catch (error) {
      status = ScanStatus.error;
      errorMessage = error.toString();
      notifyListeners();
    } finally {
      client.close();
    }
  }

  void _beginScanSession() {
    status = ScanStatus.scanning;
    result = null;
    errorMessage = null;
    agentSteps = [
      AgentStep(step: 1, label: 'Preparing input', status: 'running'),
      AgentStep(step: 2, label: 'Semantic analysis', status: 'pending'),
      AgentStep(step: 3, label: 'Evidence-based risk scoring', status: 'pending'),
      AgentStep(step: 4, label: 'Threat intelligence & grounded report', status: 'pending'),
    ];
    notifyListeners();
  }

  void _parseSseBlock(String block) {
    for (final line in block.split('\n')) {
      if (!line.startsWith('data:')) continue;
      final raw = line.substring(5).trim();
      if (raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) handleSseEvent(decoded);
      } catch (_) {
        // Ignore malformed event frames; the stream can continue with later frames.
      }
    }
  }

  @visibleForTesting
  void handleSseEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'step':
        final stepNumber = _asStep(event['step']);
        if (stepNumber == null || stepNumber < 1 || stepNumber > agentSteps.length) return;
        final step = agentSteps[stepNumber - 1];
        step.label = event['label']?.toString() ?? step.label;
        step.status = event['status']?.toString() ?? step.status;
        step.durationMs = event['duration_ms'] == null ? step.durationMs : ScanResult._asInt(event['duration_ms']);
        notifyListeners();
        break;
      case 'result':
        result = ScanResult.fromJson(event);
        status = ScanStatus.done;
        totalScansToday += 1;
        if (result!.threatLevel == ThreatLevel.high || result!.threatLevel == ThreatLevel.critical) {
          threatsBlocked += 1;
        }
        notifyListeners();
        break;
      case 'error':
        status = ScanStatus.error;
        errorMessage = event['message']?.toString() ?? 'Analysis failed';
        notifyListeners();
        break;
      case 'done':
        if (status != ScanStatus.error && result != null) status = ScanStatus.done;
        notifyListeners();
        break;
    }
  }

  int? _asStep(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
