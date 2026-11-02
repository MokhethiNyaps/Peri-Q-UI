import 'package:flutter/material.dart';

/// A flame-coloured bar that grows as the kitchen confirms each order step.
///
/// [progress] is between 0 and 1. The growth animates over 700 ms unless the
/// system asks for reduced motion.
class FlameProgress extends StatelessWidget {
  const FlameProgress({super.key, required this.progress, this.label});

  final double progress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: label ?? 'Order progress',
      value: '${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.white.withValues(alpha: 0.16)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: t,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFC8240B),
                            Color(0xFFF07820),
                            Color(0xFFFFB15C),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
