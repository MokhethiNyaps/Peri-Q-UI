import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'auth_screen.dart';
import 'customer_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Timer(const Duration(seconds: 2), () async {
      await widget.controller.bootstrapFuture;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.controller.hasReturningSession
              ? CustomerShell(controller: widget.controller)
              : AuthScreen(controller: widget.controller),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: -120,
            left: -60,
            right: -60,
            child: Container(
              height: 360,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x66C8240B),
                    Color(0x44F07820),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66C8240B),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "RASTA'S",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 5,
                      ),
                ),
                Text(
                  'PERI Q',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                      ),
                ),
                Text(
                  'CHESANYAMA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Authentically Grilled. Delivered Hot.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _animationController.value,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    color: AppTheme.periRed,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
