import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/scan_provider.dart';

class AgentStepsPanel extends StatelessWidget {
  const AgentStepsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded,
                        color: Color(0xFF00D4FF), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Agentic Pipeline',
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _PulsingDot(
                      active: provider.status == ScanStatus.scanning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.agentSteps.asMap().entries.map((e) {
                  final idx = e.key;
                  final step = e.value;
                  return _StepRow(
                    step: step,
                    isLast: idx == provider.agentSteps.length - 1,
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
    Color iconColor;
    Widget icon;

    switch (step.status) {
      case 'done':
        iconColor = const Color(0xFF00FF94);
        icon = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF00FF94), size: 20);
        break;
      case 'running':
        iconColor = const Color(0xFF00D4FF);
        icon = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00D4FF),
          ),
        );
        break;
      case 'error':
        iconColor = const Color(0xFFFF3B5C);
        icon = const Icon(Icons.error_rounded,
            color: Color(0xFFFF3B5C), size: 20);
        break;
      default:
        iconColor = const Color(0xFF2D3748);
        icon = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2D3748), width: 2),
          ),
          child: Center(
            child: Text(
              '${step.step}',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: const Color(0xFF4A5568),
              ),
            ),
          ),
        );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              icon,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: iconColor.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      step.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: step.status == 'pending'
                            ? const Color(0xFF4A5568)
                            : Colors.white,
                        fontWeight: step.status == 'running'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (step.durationMs != null)
                    Text(
                      '${(step.durationMs! / 1000).toStringAsFixed(1)}s',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: const Color(0xFF4A5568),
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

class _PulsingDot extends StatefulWidget {
  final bool active;
  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2D3748),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF00D4FF),
          ),
        ),
      ),
    );
  }
}
