import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RoadmapSection extends StatelessWidget {
  const RoadmapSection({super.key});

  static const _phases = [
    _Phase(
      phase: 'MVP',
      title: 'Web Intelligence Hub',
      status: 'Live',
      color: AppColors.green,
      icon: Icons.language_rounded,
      items: [
        'URL, text, and image scan inputs',
        'Gemini 2.5 Flash analysis pipeline',
        'Bilingual recommendations',
      ],
    ),
    _Phase(
      phase: 'Q3 2026',
      title: 'Messaging Triage',
      status: 'Planned',
      color: AppColors.cyan,
      icon: Icons.chat_rounded,
      items: [
        'Forward suspicious messages',
        'In-chat verification response',
        'Group alert broadcasts',
      ],
    ),
    _Phase(
      phase: 'Q4 2026',
      title: 'Mobile Protection',
      status: 'Planned',
      color: AppColors.violet,
      icon: Icons.smartphone_rounded,
      items: [
        'iOS and Android app shell',
        'SMS and call-risk scanning',
        'Local-first privacy controls',
      ],
    ),
  ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: AppColors.violet, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Roadmap',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Near-term evolution without adding production integrations in this rebuild',
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
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 780;
              if (!wide) {
                return Column(
                  children: _phases
                      .map((phase) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PhaseTile(phase: phase),
                          ))
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _phases
                    .map((phase) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _PhaseTile(phase: phase),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  final _Phase phase;

  const _PhaseTile({required this.phase});

  @override
  Widget build(BuildContext context) {
    final live = phase.status == 'Live';

    return Container(
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(
          color: live ? phase.color.withOpacity(0.45) : AppColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(phase.icon, color: phase.color, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phase.phase,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: phase.color),
                ),
              ),
              Text(
                phase.status,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: live ? AppColors.green : AppColors.faint,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            phase.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...phase.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    live
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: live ? phase.color : AppColors.faint,
                    size: 14,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Phase {
  final String phase;
  final String title;
  final String status;
  final Color color;
  final IconData icon;
  final List<String> items;

  const _Phase({
    required this.phase,
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
    required this.items,
  });
}
