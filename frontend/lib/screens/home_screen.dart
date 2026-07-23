import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/scan_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_steps_panel.dart';
import '../widgets/input_panel.dart';
import '../widgets/result_card.dart';
import '../widgets/roadmap_section.dart';
import '../widgets/stats_banner.dart';
import '../widgets/trending_scams.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.ink,
          border: Border(
            top: BorderSide(color: AppColors.cyan, width: 2),
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _TopBar()),
              SliverToBoxAdapter(
                child: _PageShell(
                  child: Column(
                    children: const [
                      StatsBanner(),
                      SizedBox(height: 18),
                      _ScanWorkspace(),
                      SizedBox(height: 22),
                      TrendingScams(),
                      SizedBox(height: 22),
                      RoadmapSection(),
                      _Footer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageShell extends StatelessWidget {
  final Widget child;

  const _PageShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.stroke)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                return Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: compact ? constraints.maxWidth : 430,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.panel),
                              border: Border.all(
                                color: AppColors.cyan.withOpacity(0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppColors.cyan,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ShieldScan AI',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Malaysia Fraud Intelligence Hub',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<ScanProvider>(
                      builder: (context, provider, _) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              icon: provider.status == ScanStatus.error
                                  ? Icons.error_rounded
                                  : Icons.cloud_done_rounded,
                              label: provider.status == ScanStatus.error
                                  ? 'Attention needed'
                                  : 'API ready',
                              color: provider.status == ScanStatus.error
                                  ? AppColors.red
                                  : AppColors.green,
                            ),
                            const _StatusChip(
                              icon: Icons.translate_rounded,
                              label: 'EN + BM',
                              color: AppColors.violet,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: color.withOpacity(0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ScanWorkspace extends StatelessWidget {
  const _ScanWorkspace();

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final output = _OutputPanel(provider: provider);

            if (!wide) {
              return Column(
                children: [
                  const _WorkspaceIntro(),
                  const SizedBox(height: 14),
                  const InputPanel(),
                  const SizedBox(height: 14),
                  output,
                ],
              );
            }

            return Column(
              children: [
                const _WorkspaceIntro(),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 9, child: InputPanel()),
                    const SizedBox(width: 16),
                    Expanded(flex: 10, child: output),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WorkspaceIntro extends StatelessWidget {
  const _WorkspaceIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.stroke),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan suspicious links, messages, and screenshots',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Real-time agent steps combine Gemini analysis with Malaysian fraud pattern matching, then return practical guidance in English and Bahasa Malaysia.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _MetricPill(label: 'Target', value: '< 10s'),
              _MetricPill(label: 'Signals', value: 'URL/Text/Image'),
              _MetricPill(label: 'Mode', value: 'Demo Safe'),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: text),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _OutputPanel extends StatelessWidget {
  final ScanProvider provider;

  const _OutputPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.status == ScanStatus.idle) {
      return const _EmptyAnalysisPanel();
    }

    return Column(
      children: [
        const AgentStepsPanel(),
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 14),
          _ErrorPanel(message: provider.errorMessage!),
        ],
        if (provider.result != null) ...[
          const SizedBox(height: 14),
          const ResultCard(),
        ],
      ],
    );
  }
}

class _EmptyAnalysisPanel extends StatelessWidget {
  const _EmptyAnalysisPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics_outlined, color: AppColors.cyan, size: 28),
          const SizedBox(height: 14),
          Text(
            'Analysis output is ready',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a sample or paste suspicious content. The pipeline will show classification, model analysis, fraud database matching, and bilingual recommendations here.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.route_rounded,
                label: '4-step pipeline',
                color: AppColors.cyan,
              ),
              _StatusChip(
                icon: Icons.policy_rounded,
                label: 'Actionable report',
                color: AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.red.withOpacity(0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 8),
      child: Text(
        'ShieldScan AI · GDG On Campus UTM · Project 2030 Hackathon',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppColors.faint),
      ),
    );
  }
}
