import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'customer_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool usePhone = true;
  bool isSubmitting = false;
  late final TextEditingController phoneController;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(
      text: widget.controller.customerPhone.replaceFirst('+27', '').trim(),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _openCustomerShell() async {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CustomerShell(controller: widget.controller),
      ),
    );
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => isSubmitting = true);

    try {
      await action();
      await _openCustomerShell();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/brand_mark.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Peri Q',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.periRed,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Fast ordering for local flavour.',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in quickly or continue as a guest to place your order.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.mutedSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Phone Number'),
                            selected: usePhone,
                            onSelected: (_) => setState(() => usePhone = true),
                            selectedColor: AppTheme.periRed,
                            labelStyle: TextStyle(
                              color: usePhone ? Colors.white : AppTheme.ashGrey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Email'),
                            selected: !usePhone,
                            onSelected: (_) => setState(() => usePhone = false),
                            selectedColor: AppTheme.periRed,
                            labelStyle: TextStyle(
                              color: !usePhone ? Colors.white : AppTheme.ashGrey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (usePhone) ...[
                    Text('Phone Number', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.mutedSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('+27'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '71 234 5678',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text('Email', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'your@email.com'),
                    ),
                    const SizedBox(height: 16),
                    Text('Password', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _runAuthAction(() async {
                            if (usePhone) {
                              final phone = phoneController.text.trim();
                              if (phone.isEmpty) {
                                throw Exception('Enter your phone number first.');
                              }
                              await widget.controller.startPhoneSession(phone: phone);
                              return;
                            }

                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            if (email.isEmpty || password.isEmpty) {
                              throw Exception('Enter both your email and password.');
                            }
                            await widget.controller.signInWithEmail(
                              email: email,
                              password: password,
                            );
                          }),
                    child: Text(usePhone ? 'Continue with Phone' : 'Sign In'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Google sign-in needs OAuth setup in Supabase first. Use email or guest mode for now.',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _runAuthAction(
                              widget.controller.startGuestSession,
                            ),
                    child: const Text('Continue as Guest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
