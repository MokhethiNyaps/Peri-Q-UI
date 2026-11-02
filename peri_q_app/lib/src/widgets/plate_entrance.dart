import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sets a dish photo down with a short quarter-turn, like a plate placed on
/// the counter. Runs once when the widget first appears, uses only transforms
/// (cheap on low-end Android), and is skipped when the system asks for
/// reduced motion.
class PlateEntrance extends StatelessWidget {
  const PlateEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        return Transform.rotate(
          angle: (1 - t) * -math.pi / 14,
          child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
        );
      },
    );
  }
}
