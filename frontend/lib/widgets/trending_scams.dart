import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TrendingScams extends StatelessWidget {
  const TrendingScams({super.key});

  static const _scams = [
    _ScamSignal(
      title: 'Fake LHDN Tax Arrears Call',
      level: 'HIGH',
      color: AppColors.red,
      description:
          'Impersonates tax officers and demands immediate bank transfer.',
      source: 'PDRM CCID · April 2026',
      icon: Icons.phone_in_talk_rounded,
    ),
    _ScamSignal(
      title: 'Malicious Cleaning Service APK',
      level: 'CRITICAL',
      color: AppColors.red,
      description:
          'Fake service APK steals OTP messages and drains banking wallets.',
      source: 'MCMC Advisory · March 2026',
      icon: Icons.android_rounded,
    ),
    _ScamSignal(
      title: 'Telegram Part-Time Job Scam',
      level: 'HIGH',
      color: AppColors.red,
      description:
          'Fake task jobs request deposits before releasing supposed salary.',
      source: 'BNM Alert · April 2026',
      icon: Icons.work_outline_rounded,
    ),
    _ScamSignal(
      title: 'WhatsApp Lucky Draw Prize',
      level: 'MEDIUM',
      color: AppColors.orange,
      description:
          'Claims cash prizes and asks for processing fees to release winnings.',
      source: 'PDRM CCID · April 2026',
      icon: Icons.card_giftcard_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      icon: Icons.local_fire_department_rounded,
      title: 'Trending Scam Signals',
      subtitle: 'Demo intelligence feed for Malaysian fraud patterns',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 860 ? 4 : 2;
          final spacing = 10.0;
          final tileWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _scams
                .map((scam) => SizedBox(
                      width: tileWidth,
                      child: _ScamTile(signal: scam),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _ScamTile extends StatelessWidget {
  final _ScamSignal signal;

  const _ScamTile({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(signal.icon, color: signal.color, size: 19),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: signal.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Text(
                  signal.level,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: signal.color, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            signal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              signal.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Text(
            signal.source,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.faint, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionFrame({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

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
              Icon(icon, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
          child,
        ],
      ),
    );
  }
}

class _ScamSignal {
  final String title;
  final String level;
  final Color color;
  final String description;
  final String source;
  final IconData icon;

  const _ScamSignal({
    required this.title,
    required this.level,
    required this.color,
    required this.description,
    required this.source,
    required this.icon,
  });
}
