import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_controller.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'data/local/shared_preferences_repository.dart';
import 'data/supabase/supabase_auth_repository.dart';
import 'data/supabase/supabase_menu_repository.dart';
import 'data/supabase/supabase_order_repository.dart';
import 'data/supabase/supabase_store_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/supabase_config_missing_screen.dart';

class PeriQApp extends StatefulWidget {
  const PeriQApp({
    super.key,
    required this.supabaseConfig,
  });

  final SupabaseConfig supabaseConfig;

  @override
  State<PeriQApp> createState() => _PeriQAppState();
}

class _PeriQAppState extends State<PeriQApp> {
  AppController? controller;

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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Peri Q',
        theme: AppTheme.lightTheme,
        home: const SupabaseConfigMissingScreen(),
      );
    }

    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Peri Q',
          theme: AppTheme.lightTheme,
          home: SplashScreen(controller: controller!),
        );
      },
    );
  }
}
