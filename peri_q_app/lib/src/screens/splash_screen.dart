import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import 'auth_screen.dart';
import 'customer_shell.dart';
import 'startup_error_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

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

    Future.wait<void>([
      widget.controller.bootstrapFuture,
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]).then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.controller.hasReturningSession
              ? CustomerShell(controller: widget.controller)
              : widget.controller.bootstrapError != null
              ? StartupErrorScreen(controller: widget.controller)
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
      backgroundColor: const Color(0xFFFBF1EC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo-squere.png',
                      fit: BoxFit.contain,
                    ),
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
                    backgroundColor: const Color(0x1AC8240B),
                    color: const Color(0xFFC8240B),
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
