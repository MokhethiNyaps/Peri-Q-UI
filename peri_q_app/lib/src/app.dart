import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_controller.dart';
import 'core/auth_deep_links.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'data/local/shared_preferences_repository.dart';
import 'data/supabase/supabase_auth_repository.dart';
import 'data/supabase/supabase_menu_repository.dart';
import 'data/supabase/supabase_order_repository.dart';
import 'data/supabase/supabase_store_repository.dart';
import 'repositories/notification_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/supabase_config_missing_screen.dart';

class PeriQApp extends StatefulWidget {
  const PeriQApp({
    super.key,
    required this.supabaseConfig,
    this.notificationRepository = const NoopNotificationRepository(),
  });

  final SupabaseConfig supabaseConfig;
  final NotificationRepository notificationRepository;

  @override
  State<PeriQApp> createState() => _PeriQAppState();
}

class _PeriQAppState extends State<PeriQApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AppController? controller;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  bool _hasPendingPasswordRecoveryLink = false;
  bool _isShowingPasswordRecovery = false;

  @override
  void initState() {
    super.initState();

    if (!widget.supabaseConfig.isConfigured) {
      return;
    }

    final client = Supabase.instance.client;
    controller = AppController(
      authRepository: SupabaseAuthRepository(client: client),
      menuRepository: SupabaseMenuRepository(client: client),
      orderRepository: SupabaseOrderRepository(client: client),
      preferencesRepository: SharedPreferencesRepository(),
      storeRepository: SupabaseStoreRepository(client: client),
      notificationRepository: widget.notificationRepository,
    );

    _authSubscription = client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: _handleAuthError,
    );
    _deepLinkSubscription = AppLinks().uriLinkStream.listen(
      _handleDeepLink,
      onError: _handleDeepLinkError,
    );
  }

  void _handleDeepLink(Uri uri) {
    if (AuthDeepLinks.isPasswordReset(uri)) {
      _hasPendingPasswordRecoveryLink = true;
    }
  }

  void _handleAuthStateChange(AuthState authState) {
    final session =
        authState.session ?? Supabase.instance.client.auth.currentSession;
    final isPasswordRecovery =
        authState.event == AuthChangeEvent.passwordRecovery ||
        (_hasPendingPasswordRecoveryLink &&
            authState.event == AuthChangeEvent.signedIn);

    if (!isPasswordRecovery || session == null) {
      return;
    }

    _hasPendingPasswordRecoveryLink = false;
    _showPasswordRecoveryScreen();
  }

  void _handleAuthError(Object error, StackTrace stackTrace) {
    if (_hasPendingPasswordRecoveryLink) {
      _hasPendingPasswordRecoveryLink = false;
      _showRecoveryLinkError();
    }
  }

  void _handleDeepLinkError(Object error, StackTrace stackTrace) {
    _showRecoveryLinkError();
  }

  void _showPasswordRecoveryScreen() {
    if (_isShowingPasswordRecovery) {
      return;
    }

    _isShowingPasswordRecovery = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isShowingPasswordRecovery = false;
        return;
      }

      final navigator = _navigatorKey.currentState;
      if (navigator == null || controller == null) {
        _isShowingPasswordRecovery = false;
        return;
      }

      unawaited(
        navigator
            .pushAndRemoveUntil<void>(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/reset-password'),
                builder: (_) => ResetPasswordScreen(controller: controller!),
              ),
              (_) => false,
            )
            .whenComplete(() => _isShowingPasswordRecovery = false),
      );
    });
  }

  void _showRecoveryLinkError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (!mounted || context == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This password reset link is invalid or expired. Request a new one.',
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_deepLinkSubscription?.cancel());
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'RastasperiQ',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        themeAnimationDuration: const Duration(milliseconds: 280),
        themeAnimationCurve: Curves.easeOutCubic,
        builder: _buildThemedSystemChrome,
        home: const SupabaseConfigMissingScreen(),
      );
    }

    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'RastasperiQ',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller!.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 280),
          themeAnimationCurve: Curves.easeOutCubic,
          builder: _buildThemedSystemChrome,
          home: SplashScreen(controller: controller!),
        );
      },
    );
  }

  Widget _buildThemedSystemChrome(BuildContext context, Widget? child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
