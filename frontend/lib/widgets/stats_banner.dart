import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/scan_provider.dart';

class StatsBanner extends StatelessWidget {
  const StatsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E2D45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.search_rounded,
                label: 'Scans Today',
                value: provider.totalScansToday.toString(),
                color: const Color(0xFF00D4FF),
              ),
              _divider(),
              _StatItem(
                icon: Icons.block_rounded,
                label: 'Threats Blocked',
                value: provider.threatsBlocked.toString(),
                color: const Color(0xFFFF3B5C),
              ),
              _divider(),
              _StatItem(
                icon: Icons.language_rounded,
                label: 'Bilingual',
                value: 'EN + BM',
                color: const Color(0xFF00FF94),
              ),
              _divider(),
              _StatItem(
                icon: Icons.bolt_rounded,
                label: 'Avg Speed',
                value: '< 5s',
                color: const Color(0xFFFFA726),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Container(
      height: 32,
      width: 1,
      color: const Color(0xFF1E2D45),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: const Color(0xFF8B9AB5),
          ),
        ),
      ],
    );
  }
}
