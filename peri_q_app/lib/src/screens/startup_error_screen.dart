import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'auth_screen.dart';
import 'customer_shell.dart';

class StartupErrorScreen extends StatefulWidget {
  const StartupErrorScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<StartupErrorScreen> {
  bool retrying = false;

  Future<void> _retry() async {
    if (retrying) return;
    setState(() => retrying = true);
    await widget.controller.retryBootstrap();
    if (!mounted) return;
    if (widget.controller.bootstrapError == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.controller.hasReturningSession
              ? CustomerShell(controller: widget.controller)
              : AuthScreen(controller: widget.controller),
        ),
      );
      return;
    }
    setState(() => retrying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Still unable to connect. Check your data connection.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 72,
                  color: AppTheme.ashGrey,
                  semanticLabel: 'Connection unavailable',
                ),
                const SizedBox(height: 18),
                Text(
                  'We could not load the menu',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Check your mobile data or Wi-Fi, then try again. No order has been placed.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: retrying ? null : _retry,
                  icon: retrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(retrying ? 'Trying again...' : 'Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
