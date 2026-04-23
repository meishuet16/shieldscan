import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stats_banner.dart';
import '../widgets/input_panel.dart';
import '../widgets/agent_steps_panel.dart';
import '../widgets/result_card.dart';
import '../widgets/trending_scams.dart';
import '../widgets/roadmap_section.dart';
import '../services/scan_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF0D1829), Color(0xFF0A0E1A)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            const SliverToBoxAdapter(child: StatsBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return _wideLayout(context);
                    }
                    return _narrowLayout(context);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TrendingScams(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: RoadmapSection(),
              ),
            ),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF00D4FF),
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ShieldScan AI',
                    style: GoogleFonts.spaceMono(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Malaysia Fraud Intelligence Hub',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: const Color(0xFF00D4FF),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Headline
          Text(
            'Jaga Digital Malaysia',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Protect every Malaysian before they click.\nPowered by Gemini 1.5 Pro + Agentic AI.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: const Color(0xFF8B9AB5),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Track badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF94).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00FF94).withOpacity(0.4),
              ),
            ),
            child: Text(
              '🏆 Project 2030 — Track 5: Secure Digital',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: const Color(0xFF00FF94),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: const InputPanel()),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  if (provider.status != ScanStatus.idle)
                    const AgentStepsPanel(),
                  if (provider.result != null) ...[
                    const SizedBox(height: 16),
                    const ResultCard(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _narrowLayout(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            const InputPanel(),
            if (provider.status != ScanStatus.idle) ...[
              const SizedBox(height: 16),
              const AgentStepsPanel(),
            ],
            if (provider.result != null) ...[
              const SizedBox(height: 16),
              const ResultCard(),
            ],
          ],
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Divider(color: Color(0xFF1E2D45)),
          const SizedBox(height: 16),
          Text(
            'Built with ❤️ for Malaysia — "Advance the Nation by Building Solutions with Google AI"',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ShieldScan AI · GDG On Campus UTM · Project 2030 Hackathon',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
