import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/scan_provider.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatefulWidget {
  const ResultCard({super.key});

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _showBm = false;

  @override
  Widget build(BuildContext context) {
    final result = context.watch<ScanProvider>().result;
    if (result == null) return const SizedBox.shrink();

    final level = _LevelView.fromThreat(result.threatLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RiskHeader(result: result, level: level),
            const SizedBox(height: 16),
            _LanguageSwitch(
              showBm: _showBm,
              onChanged: (value) => setState(() => _showBm = value),
            ),
            const SizedBox(height: 14),
            _Section(
              icon: Icons.summarize_rounded,
              title: 'Analysis Summary',
              child: Text(
                _showBm ? result.summaryBm : result.summaryEn,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ),
            if (result.riskEvidence.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.rule_rounded,
                title: 'Deterministic Risk Evidence',
                child: Column(
                  children: result.riskEvidence
                      .map((evidence) => _RiskEvidenceRow(evidence: evidence))
                      .toList(),
                ),
              ),
            ],
            if (result.indicators.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.warning_amber_rounded,
                title: 'Semantic Fraud Indicators',
                child: Column(
                  children: result.indicators
                      .map((indicator) => _IndicatorRow(indicator: indicator))
                      .toList(),
                ),
              ),
            ],
            if (result.ragMatches.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.manage_search_rounded,
                title: 'Related Official Threat Intelligence',
                child: Column(
                  children: result.ragMatches
                      .map((match) => _ThreatIntelCard(match: match))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _Recommendation(
              text: _showBm
                  ? result.recommendationBm
                  : result.recommendationEn,
            ),
            const SizedBox(height: 14),
            _ReportActions(level: result.threatLevel),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Scanned in ${(result.scanDurationMs / 1000).toStringAsFixed(1)}s · ${result.scoringVersion}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskHeader extends StatelessWidget {
  final ScanResult result;
  final _LevelView level;

  const _RiskHeader({required this.result, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: level.color.withOpacity(0.32)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final riskText = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.label,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: level.color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                level.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          );
          final riskScore = _RiskScore(
            value: result.confidenceScore,
            color: level.color,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                riskText,
                const SizedBox(height: 12),
                riskScore,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: riskText),
              const SizedBox(width: 16),
              riskScore,
            ],
          );
        },
      ),
    );
  }
}

class _RiskScore extends StatelessWidget {
  final int value;
  final Color color;

  const _RiskScore({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text('risk score / 100', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  final bool showBm;
  final ValueChanged<bool> onChanged;

  const _LanguageSwitch({
    required this.showBm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Report language', style: Theme.of(context).textTheme.labelMedium),
        _LangButton(
          label: 'English',
          selected: !showBm,
          onTap: () => onChanged(false),
        ),
        _LangButton(
          label: 'Bahasa Malaysia',
          selected: showBm,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withOpacity(0.12) : AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.small),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.cyan : AppColors.muted,
              ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.cyan, size: 17),
            const SizedBox(width: 7),
            Text(title, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RiskEvidenceRow extends StatelessWidget {
  final RiskEvidence evidence;

  const _RiskEvidenceRow({required this.evidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Text(
              '+${evidence.score}',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.orange, fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (evidence.evidence.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    evidence.evidence,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final FraudIndicator indicator;

  const _IndicatorRow({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final color = switch (indicator.severity.toLowerCase()) {
      'high' => AppColors.red,
      'medium' => AppColors.orange,
      _ => AppColors.green,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Text(
              indicator.severity.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color, fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  indicator.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatIntelCard extends StatelessWidget {
  final ThreatIntelMatch match;

  const _ThreatIntelCard({required this.match});

  Future<void> _openSource() async {
    final value = match.sourceUrl;
    if (value == null || value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null || !const {'https', 'http'}.contains(uri.scheme)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasSource = match.sourceUrl?.isNotEmpty ?? false;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.cyan.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            match.sourceName,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.cyan),
          ),
          if (match.summary.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              match.summary,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
          if (hasSource) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openSource,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('View official source'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.cyan,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  final String text;

  const _Recommendation({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.orange.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Action',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.orange),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportActions extends StatelessWidget {
  final ThreatLevel level;

  const _ReportActions({required this.level});

  @override
  Widget build(BuildContext context) {
    final urgent = level == ThreatLevel.high || level == ThreatLevel.critical;

    return Column(
      children: [
        if (urgent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppRadii.panel),
              border: Border.all(color: AppColors.red.withOpacity(0.22)),
            ),
            child: Text(
              'If money was transferred or credentials were exposed, contact your bank immediately and call NSRC 997. Lodge a police report as soon as possible.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.muted, height: 1.5),
            ),
          ),
      ],
    );
  }
}

class _LevelView {
  final String label;
  final String description;
  final Color color;

  const _LevelView({
    required this.label,
    required this.description,
    required this.color,
  });

  factory _LevelView.fromThreat(ThreatLevel level) {
    return switch (level) {
      ThreatLevel.safe => const _LevelView(
          label: 'SAFE',
          description: 'No significant fraud indicators detected in this scan.',
          color: AppColors.green,
        ),
      ThreatLevel.low => const _LevelView(
          label: 'LOW RISK',
          description: 'Minor suspicious elements. Proceed with caution.',
          color: AppColors.orange,
        ),
      ThreatLevel.medium => const _LevelView(
          label: 'MEDIUM RISK',
          description: 'Multiple signals need independent verification.',
          color: AppColors.orange,
        ),
      ThreatLevel.high => const _LevelView(
          label: 'HIGH RISK',
          description: 'Strong fraud indicators. Do not proceed without verification.',
          color: AppColors.red,
        ),
      ThreatLevel.critical => const _LevelView(
          label: 'CRITICAL',
          description: 'Very strong fraud indicators. Stop and verify through official channels.',
          color: AppColors.red,
        ),
    };
  }
}
