import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoadmapSection extends StatelessWidget {
  const RoadmapSection({super.key});

  static const _phases = [
    {
      'phase': 'MVP — NOW',
      'title': 'Web Intelligence Hub',
      'color': 0xFF00FF94,
      'icon': Icons.language_rounded,
      'current': true,
      'items': [
        'Multimodal scanning: URL, text, image',
        'Gemini 2.5 Flash agentic pipeline',
        'Bilingual reports (EN + BM)',
        'PDRM/BNM/MCMC RAG database',
        'Deployed on Google Cloud Run',
      ],
    },
    {
      'phase': 'Q3 2026',
      'title': 'WhatsApp Bot Integration',
      'color': 0xFF00D4FF,
      'icon': Icons.chat_rounded,
      'current': false,
      'items': [
        'Forward suspicious messages to ShieldScan Bot',
        'Instant AI verification in-chat',
        'Group scam alert broadcasts',
        'Integration with NSRC (997) hotline',
      ],
    },
    {
      'phase': 'Q4 2026',
      'title': 'ShieldScan Mobile App',
      'color': 0xFFA78BFA,
      'icon': Icons.smartphone_rounded,
      'current': false,
      'items': [
        'iOS + Android native app',
        'Real-time background SMS scanning',
        'Incoming scam call blocking (PDRM CCID database)',
        'Malaysia\'s AI-powered ScamShield equivalent',
      ],
    },
    {
      'phase': 'Q1 2027',
      'title': 'Federated AI Defence Network',
      'color': 0xFFFFA726,
      'icon': Icons.hub_rounded,
      'current': false,
      'items': [
        'Federated Learning — user reports train AI locally',
        'Zero data privacy compromise',
        'Bank API integration (Maybank, CIMB, RHB)',
        'MyDIGITAL government portal integration',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFA78BFA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Color(0xFFA78BFA), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚀 Product Roadmap',
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'From Web MVP → Malaysia\'s AI-Powered ScamShield',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF8B9AB5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Roadmap phases
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildHorizontal();
            }
            return _buildVertical();
          },
        ),
        const SizedBox(height: 20),
        // Vision statement
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4FF).withOpacity(0.05),
                const Color(0xFFA78BFA).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                '"ShieldScan AI is not just a hackathon project —\nit is the beginning of Malaysia\'s indigenous fraud protection infrastructure."',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: const Color(0xFFCBD5E0),
                  fontStyle: FontStyle.italic,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AlignBadge(label: 'NIMP 2030'),
                  const SizedBox(width: 8),
                  _AlignBadge(label: 'MyDIGITAL'),
                  const SizedBox(width: 8),
                  _AlignBadge(label: 'Malaysia Madani'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHorizontal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _phases.asMap().entries.map((e) {
        final isLast = e.key == _phases.length - 1;
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PhaseCard(phase: e.value)),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: const Color(0xFF2D3748), size: 20),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVertical() {
    return Column(
      children: _phases
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PhaseCard(phase: p),
              ))
          .toList(),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final Map<String, dynamic> phase;
  const _PhaseCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    final color = Color(phase['color'] as int);
    final isCurrent = phase['current'] as bool;
    final items = phase['items'] as List<String>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withOpacity(0.06)
            : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color.withOpacity(0.5) : const Color(0xFF1E2D45),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(phase['icon'] as IconData, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  phase['phase'] as String,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            phase['title'] as String,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCurrent
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isCurrent ? color : const Color(0xFF2D3748),
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: isCurrent
                            ? const Color(0xFFCBD5E0)
                            : const Color(0xFF6B7280),
                        height: 1.4,
                      ),
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

class _AlignBadge extends StatelessWidget {
  final String label;
  const _AlignBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          color: const Color(0xFF00D4FF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
