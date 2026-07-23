import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/scan_provider.dart';
import '../theme/app_theme.dart';

class StatsBanner extends StatelessWidget {
  const StatsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final stats = [
          _StatData(
            icon: Icons.search_rounded,
            label: 'Scans Today',
            value: provider.totalScansToday.toString(),
            color: AppColors.cyan,
          ),
          _StatData(
            icon: Icons.block_rounded,
            label: 'Threats Blocked',
            value: provider.threatsBlocked.toString(),
            color: AppColors.red,
          ),
          const _StatData(
            icon: Icons.translate_rounded,
            label: 'Language',
            value: 'EN + BM',
            color: AppColors.green,
          ),
          const _StatData(
            icon: Icons.bolt_rounded,
            label: 'Target Speed',
            value: '< 10s',
            color: AppColors.orange,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            final spacing = 10.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: stats
                  .map((stat) => SizedBox(
                        width: width,
                        child: _StatTile(data: stat),
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatTile extends StatelessWidget {
  final _StatData data;

  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
