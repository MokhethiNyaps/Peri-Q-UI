import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
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
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion && _animationController.isAnimating) {
      _animationController.stop();
    } else if (!reduceMotion && !_animationController.isAnimating) {
      _animationController.repeat();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  image: true,
                  label: 'RastasperiQ',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 240,
                      maxHeight: 240,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.appColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(AppRadii.panel),
                          border: Border.all(
                            color: context.appColors.softOutline,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.shadow,
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.panel),
                          child: Image.asset(
                            'assets/images/logo-squere.png',
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
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
                    value: reduceMotion ? null : _animationController.value,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    color: theme.colorScheme.primary,
                    semanticsLabel: 'Loading RastasperiQ',
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
