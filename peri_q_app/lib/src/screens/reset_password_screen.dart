import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'auth_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      await widget.controller.updatePassword(
        newPassword: _passwordController.text,
      );
      await widget.controller.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthScreen(controller: widget.controller),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _returnToSignIn() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.controller.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthScreen(controller: widget.controller),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Update Password')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        size: 72,
                        color: AppTheme.periRed,
                        semanticLabel: 'Password recovery',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Choose a new password.',
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your recovery link has been verified. Enter a new password for your Peri Q account.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      TextFormField(
                        key: const ValueKey('reset-password-field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          hintText: 'At least 6 characters',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        key: const ValueKey('reset-password-confirm-field'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          hintText: 'Repeat your new password',
                        ),
                        validator: _validateConfirmation,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _updatePassword(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        key: const ValueKey('reset-password-submit-button'),
                        onPressed: _isSubmitting ? null : _updatePassword,
                        child: Text(
                          _isSubmitting ? 'Updating...' : 'Update Password',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        key: const ValueKey('reset-password-back-button'),
                        onPressed: _isSubmitting ? null : _returnToSignIn,
                        child: const Text('Back to Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    final authMatch = RegExp(
      r'AuthException\(message: ([^,)]+)',
    ).firstMatch(text);
    if (authMatch != null) {
      return authMatch.group(1)!;
    }

    return text.replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
  }
}
