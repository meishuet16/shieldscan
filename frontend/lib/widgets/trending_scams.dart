import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingScams extends StatelessWidget {
  const TrendingScams({super.key});

  static const _scams = [
    {
      'title': 'Fake LHDN Tax Arrears Call',
      'level': 'HIGH',
      'color': 0xFFFF3B5C,
      'desc': 'Scammers impersonating LHDN officers demanding immediate tax payment via bank transfer.',
      'source': 'PDRM CCID · April 2026',
      'icon': Icons.phone_in_talk_rounded,
    },
    {
      'title': 'Malicious Cleaning Service APK',
      'level': 'CRITICAL',
      'color': 0xFFFF0040,
      'desc': 'Fake maid/cleaning APK hijacking SMS OTPs and draining Maybank2u / Touch \'n Go accounts.',
      'source': 'MCMC Advisory · March 2026',
      'icon': Icons.android_rounded,
    },
    {
      'title': 'Telegram Part-Time Job Scam',
      'level': 'HIGH',
      'color': 0xFFFF3B5C,
      'desc': 'Fake product-reviewing jobs on Telegram asking for upfront deposit before releasing "salary".',
      'source': 'BNM Alert · April 2026',
      'icon': Icons.work_outline_rounded,
    },
    {
      'title': 'WhatsApp "Lucky Draw" Prize Scam',
      'level': 'MEDIUM',
      'color': 0xFFFF9800,
      'desc': 'Mass WhatsApp blast claiming winners of RM5,000–RM50,000, requiring "processing fee" to claim.',
      'source': 'PDRM CCID · April 2026',
      'icon': Icons.card_giftcard_rounded,
    },
    {
      'title': 'Macau Scam — Police Impersonation',
      'level': 'CRITICAL',
      'color': 0xFFFF0040,
      'desc': 'Caller claims to be PDRM/BNM officer, accuses victim of money laundering, demands fund transfer.',
      'source': 'PDRM CCID · Ongoing',
      'icon': Icons.local_police_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF3B5C), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 Trending Scams in Malaysia',
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Live PDRM / BNM / MCMC Feed — Updated April 2026',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF8B9AB5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Scam cards grid
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              // Two-column grid
              return _buildGrid();
            }
            return _buildList();
          },
        ),
        const SizedBox(height: 8),
        // Disclaimer
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF4A5568), size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Data sourced from PDRM Cybercrime Division, BNM, and MCMC consumer reports. '
                'Paste any suspicious content above to scan it instantly.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: const Color(0xFF4A5568),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _scams.map((s) {
        return SizedBox(
          width: 320,
          child: _ScamCard(scam: s),
        );
      }).toList(),
    );
  }

  Widget _buildList() {
    return Column(
      children: _scams
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScamCard(scam: s),
              ))
          .toList(),
    );
  }
}

class _ScamCard extends StatelessWidget {
  final Map<String, dynamic> scam;
  const _ScamCard({required this.scam});

  @override
  Widget build(BuildContext context) {
    final color = Color(scam['color'] as int);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(scam['icon'] as IconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scam['title'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scam['level'] as String,
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  scam['desc'] as String,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF8B9AB5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scam['source'] as String,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: const Color(0xFF4A5568),
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
