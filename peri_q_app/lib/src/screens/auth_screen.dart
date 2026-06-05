import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'customer_shell.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  _AuthMode mode = _AuthMode.signIn;
  bool isSubmitting = false;

  late final TextEditingController phoneController;
  final signInEmailController = TextEditingController();
  final signInPasswordController = TextEditingController();
  final signUpNameController = TextEditingController();
  final signUpPhoneController = TextEditingController();
  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpConfirmPasswordController = TextEditingController();
  final resetEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(
      text: widget.controller.customerPhone.replaceFirst('+27', '').trim(),
    );
    signUpPhoneController.text = phoneController.text;
  }

  @override
  void dispose() {
    phoneController.dispose();
    signInEmailController.dispose();
    signInPasswordController.dispose();
    signUpNameController.dispose();
    signUpPhoneController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    signUpConfirmPasswordController.dispose();
    resetEmailController.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _submitEmailAuth() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (mode == _AuthMode.signIn) {
      await _runAuthAction(
        () => widget.controller.signInWithEmail(
          email: signInEmailController.text.trim(),
          password: signInPasswordController.text,
        ),
      );
      return;
    }

    await _runAuthAction(
      () => widget.controller.registerWithEmail(
        name: signUpNameController.text.trim(),
        phone: signUpPhoneController.text.trim(),
        email: signUpEmailController.text.trim(),
        password: signUpPasswordController.text,
      ),
    );
  }

  Future<void> _continueWithPhone() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) {
      return;
    }

    await _runAuthAction(
      () => widget.controller.startPhoneSession(
        phone: phoneController.text.trim(),
      ),
    );
  }

  Future<void> _showPasswordResetDialog() async {
    resetEmailController.text = signInEmailController.text.trim().isNotEmpty
        ? signInEmailController.text.trim()
        : signUpEmailController.text.trim();
    final resetFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: resetFormKey,
                child: TextFormField(
                  key: const ValueKey('auth-reset-email-field'),
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                  ),
                  validator: _validateEmail,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!(resetFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            await widget.controller.requestPasswordReset(
                              email: resetEmailController.text.trim(),
                            );
                            if (!dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            if (!mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password reset email sent. Check your inbox.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!dialogContext.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(_messageFromError(error))),
                            );
                            setDialogState(() => isSending = false);
                          }
                        },
                  child: Text(isSending ? 'Sending...' : 'Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _setMode(_AuthMode nextMode) {
    if (mode == nextMode) {
      return;
    }

    setState(() => mode = nextMode);
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = mode == _AuthMode.signIn;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrandHeader(),
                  const SizedBox(height: 28),
                  Text(
                    isSignIn ? 'Welcome back.' : 'Create your account.',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isSignIn
                        ? 'Sign in with email, continue with phone, or order as a guest.'
                        : 'Save your details and track every Peri Q order from one account.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  _AuthModeSwitch(mode: mode, onChanged: _setMode),
                  const SizedBox(height: 24),
                  Form(
                    key: _emailFormKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: isSignIn
                          ? _SignInFields(
                              key: const ValueKey('auth-sign-in-fields'),
                              emailController: signInEmailController,
                              passwordController: signInPasswordController,
                              onForgotPassword: _showPasswordResetDialog,
                              validateEmail: _validateEmail,
                              validatePassword: _validateSignInPassword,
                            )
                          : _SignUpFields(
                              key: const ValueKey('auth-sign-up-fields'),
                              nameController: signUpNameController,
                              phoneController: signUpPhoneController,
                              emailController: signUpEmailController,
                              passwordController: signUpPasswordController,
                              confirmPasswordController:
                                  signUpConfirmPasswordController,
                              validateName: _validateName,
                              validatePhone: _validatePhone,
                              validateEmail: _validateEmail,
                              validatePassword: _validateNewPassword,
                              validateConfirmPassword: _validateConfirmPassword,
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    key: ValueKey(
                      isSignIn ? 'auth-sign-in-button' : 'auth-sign-up-button',
                    ),
                    onPressed: isSubmitting ? null : _submitEmailAuth,
                    child: Text(isSignIn ? 'Sign In' : 'Create Account'),
                  ),
                  if (isSignIn) ...[
                    const SizedBox(height: 22),
                    _SectionDivider(label: 'Quick order'),
                    const SizedBox(height: 18),
                    Form(
                      key: _phoneFormKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: _PhoneField(
                        fieldKey: const ValueKey('auth-phone-field'),
                        controller: phoneController,
                        validator: _validatePhone,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      key: const ValueKey('auth-phone-button'),
                      onPressed: isSubmitting ? null : _continueWithPhone,
                      icon: const Icon(Icons.phone_android_rounded),
                      label: const Text('Continue with Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('auth-guest-button'),
                      onPressed: isSubmitting
                          ? null
                          : () => _runAuthAction(
                              widget.controller.startGuestSession,
                            ),
                      child: const Text('Continue as Guest'),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        key: const ValueKey('auth-existing-account-button'),
                        onPressed: isSubmitting
                            ? null
                            : () => _setMode(_AuthMode.signIn),
                        child: const Text('Already have an account? Sign In'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter your full name.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateSignInPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != signUpPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[\s()-]'), '');
    if (normalized.length < 8) {
      return 'Enter a valid phone number.';
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

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: AppTheme.periRed),
        ),
      ],
    );
  }
}

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.mutedSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              key: const ValueKey('auth-sign-in-tab'),
              label: const Text('Sign In'),
              selected: mode == _AuthMode.signIn,
              onSelected: (_) => onChanged(_AuthMode.signIn),
              selectedColor: AppTheme.periRed,
              labelStyle: TextStyle(
                color: mode == _AuthMode.signIn
                    ? Colors.white
                    : AppTheme.ashGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              key: const ValueKey('auth-create-account-tab'),
              label: const Text('Create Account'),
              selected: mode == _AuthMode.signUp,
              onSelected: (_) => onChanged(_AuthMode.signUp),
              selectedColor: AppTheme.periRed,
              labelStyle: TextStyle(
                color: mode == _AuthMode.signUp
                    ? Colors.white
                    : AppTheme.ashGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInFields extends StatelessWidget {
  const _SignInFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onForgotPassword,
    required this.validateEmail,
    required this.validatePassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onForgotPassword;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const ValueKey('auth-sign-in-email-field'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'your@email.com',
          ),
          validator: validateEmail,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('auth-sign-in-password-field'),
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
          ),
          validator: validatePassword,
          textInputAction: TextInputAction.done,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey('auth-forgot-password-button'),
            onPressed: onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }
}

class _SignUpFields extends StatelessWidget {
  const _SignUpFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.validateName,
    required this.validatePhone,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validatePhone;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: const ValueKey('auth-sign-up-name-field'),
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Your name',
          ),
          validator: validateName,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _PhoneField(
          fieldKey: const ValueKey('auth-sign-up-phone-field'),
          controller: phoneController,
          validator: validatePhone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('auth-sign-up-email-field'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'your@email.com',
          ),
          validator: validateEmail,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('auth-sign-up-password-field'),
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Create a password',
          ),
          validator: validatePassword,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('auth-sign-up-confirm-password-field'),
          controller: confirmPasswordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Repeat your password',
          ),
          validator: validateConfirmPassword,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    this.fieldKey,
    required this.controller,
    required this.validator,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      decoration: const InputDecoration(
        prefixText: '+27 ',
        labelText: 'Phone Number',
        hintText: '71 234 5678',
      ),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
