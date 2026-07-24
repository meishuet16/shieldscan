import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/scan_provider.dart';
import '../theme/app_theme.dart';

class AgentStepsPanel extends StatelessWidget {
  const AgentStepsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree_rounded,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Analysis Pipeline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    _RunState(status: provider.status),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.agentSteps.asMap().entries.map((entry) {
                  return _StepRow(
                    step: entry.value,
                    isLast: entry.key == provider.agentSteps.length - 1,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  final AgentStep step;
  final bool isLast;

  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final style = _StepStyle.fromStatus(step.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _StepIcon(step: step, style: style),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: style.color.withOpacity(0.28),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(AppRadii.panel),
                  border: Border.all(color: style.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: style.text,
                              fontWeight: step.status == 'running'
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                      ),
                    ),
                    if (step.durationMs != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${(step.durationMs! / 1000).toStringAsFixed(1)}s',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.faint),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final AgentStep step;
  final _StepStyle style;

  const _StepIcon({required this.step, required this.style});

  @override
  Widget build(BuildContext context) {
    if (step.status == 'running') {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppColors.cyan,
        ),
      );
    }

    final icon = switch (step.status) {
      'done' => Icons.check_circle_rounded,
      'error' => Icons.error_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };

    return Icon(icon, color: style.color, size: 22);
  }
}

class _RunState extends StatelessWidget {
  final ScanStatus status;

  const _RunState({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ScanStatus.scanning => 'Running',
      ScanStatus.done => 'Complete',
      ScanStatus.error => 'Error',
      ScanStatus.idle => 'Ready',
    };
    final color = switch (status) {
      ScanStatus.scanning => AppColors.cyan,
      ScanStatus.done => AppColors.green,
      ScanStatus.error => AppColors.red,
      ScanStatus.idle => AppColors.faint,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _StepStyle {
  final Color color;
  final Color text;
  final Color background;
  final Color border;

  const _StepStyle({
    required this.color,
    required this.text,
    required this.background,
    required this.border,
  });

  factory _StepStyle.fromStatus(String status) {
    return switch (status) {
      'done' => _StepStyle(
          color: AppColors.green,
          text: AppColors.text,
          background: AppColors.green.withOpacity(0.06),
          border: AppColors.green.withOpacity(0.2),
        ),
      'running' => _StepStyle(
          color: AppColors.cyan,
          text: AppColors.text,
          background: AppColors.cyan.withOpacity(0.08),
          border: AppColors.cyan.withOpacity(0.28),
        ),
      'error' => _StepStyle(
          color: AppColors.red,
          text: AppColors.text,
          background: AppColors.red.withOpacity(0.08),
          border: AppColors.red.withOpacity(0.3),
        ),
      _ => const _StepStyle(
          color: AppColors.faint,
          text: AppColors.muted,
          background: AppColors.ink,
          border: AppColors.stroke,
        ),
    };
  }
}
