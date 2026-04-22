import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/scan_provider.dart';

class ResultCard extends StatefulWidget {
  const ResultCard({super.key});

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _showBm = false;

  static const _levelConfig = {
    ThreatLevel.safe: {
      'label': 'SAFE',
      'emoji': '🟢',
      'color': 0xFF00FF94,
      'bg': 0xFF00FF9410,
      'desc': 'No fraud indicators detected.',
    },
    ThreatLevel.low: {
      'label': 'LOW RISK',
      'emoji': '🟡',
      'color': 0xFFFFC107,
      'bg': 0xFFFFC10710,
      'desc': 'Minor suspicious elements. Proceed with caution.',
    },
    ThreatLevel.medium: {
      'label': 'MEDIUM RISK',
      'emoji': '🟠',
      'color': 0xFFFF9800,
      'bg': 0xFFFF980010,
      'desc': 'Multiple fraud signals. Verify before proceeding.',
    },
    ThreatLevel.high: {
      'label': 'HIGH RISK',
      'emoji': '🔴',
      'color': 0xFFFF3B5C,
      'bg': 0xFFFF3B5C15,
      'desc': 'Strong fraud indicators. Do not proceed.',
    },
    ThreatLevel.critical: {
      'label': 'CRITICAL',
      'emoji': '🚨',
      'color': 0xFFFF0040,
      'bg': 0xFFFF004020,
      'desc': 'Confirmed fraud pattern. Report immediately.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final result = context.watch<ScanProvider>().result;
    if (result == null) return const SizedBox.shrink();

    final cfg = _levelConfig[result.threatLevel]!;
    final levelColor = Color(cfg['color'] as int);
    final bgColor = Color(cfg['bg'] as int);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Threat level header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: levelColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Text(
                    cfg['emoji'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cfg['label'] as String,
                          style: GoogleFonts.spaceMono(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                        Text(
                          cfg['desc'] as String,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: levelColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Confidence score
                  Column(
                    children: [
                      Text(
                        '${result.confidenceScore}%',
                        style: GoogleFonts.spaceMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                      Text(
                        'confidence',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: const Color(0xFF8B9AB5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Language toggle
            Row(
              children: [
                const Icon(Icons.translate_rounded,
                    color: Color(0xFF8B9AB5), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Report Language:',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF8B9AB5),
                  ),
                ),
                const SizedBox(width: 12),
                _LangToggle(
                  selected: !_showBm,
                  label: 'English',
                  onTap: () => setState(() => _showBm = false),
                ),
                const SizedBox(width: 8),
                _LangToggle(
                  selected: _showBm,
                  label: 'Bahasa Malaysia',
                  onTap: () => setState(() => _showBm = true),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Summary
            _SectionLabel(label: 'Analysis Summary'),
            const SizedBox(height: 6),
            Text(
              _showBm ? result.summaryBm : result.summaryEn,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: const Color(0xFFCBD5E0),
                height: 1.6,
              ),
            ),

            // Fraud indicators
            if (result.indicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'Fraud Indicators (${result.indicators.length})'),
              const SizedBox(height: 8),
              ...result.indicators.map((ind) => _IndicatorRow(indicator: ind)),
            ],

            // RAG matches
            if (result.ragMatches.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'PDRM/BNM Database Matches'),
              const SizedBox(height: 8),
              ...result.ragMatches.map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.data_object_rounded,
                          color: Color(0xFF00D4FF), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match,
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            color: const Color(0xFF8B9AB5),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1321),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D3748)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended Action',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            color: const Color(0xFFFFC107),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _showBm
                              ? result.recommendationBm
                              : result.recommendationEn,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: const Color(0xFFCBD5E0),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scan time
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.timer_outlined,
                    color: Color(0xFF4A5568), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Scanned in ${(result.scanDurationMs / 1000).toStringAsFixed(1)}s',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),

            // Report fraud link for high/critical
            if (result.threatLevel == ThreatLevel.high ||
                result.threatLevel == ThreatLevel.critical) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B5C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF3B5C).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '🚨 Report to Authorities',
                      style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF3B5C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PDRM Cybercrime: 03-2266 2222\nBNM BNMTELELINK: 1-300-88-5465\nMCMC: 1-800-188-030',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF8B9AB5),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.spaceMono(
        fontSize: 11,
        letterSpacing: 1.5,
        color: const Color(0xFF4A5568),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final FraudIndicator indicator;
  const _IndicatorRow({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final severityColors = {
      'high': const Color(0xFFFF3B5C),
      'medium': const Color(0xFFFF9800),
      'low': const Color(0xFFFFC107),
    };
    final color = severityColors[indicator.severity] ?? const Color(0xFFFFC107);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              indicator.severity.toUpperCase(),
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.category,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  indicator.description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF8B9AB5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _LangToggle({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00D4FF).withOpacity(0.15)
              : const Color(0xFF1A2232),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? const Color(0xFF00D4FF)
                : const Color(0xFF2D3748),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: selected
                ? const Color(0xFF00D4FF)
                : const Color(0xFF8B9AB5),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
