import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_controller.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'data/local/shared_preferences_repository.dart';
import 'data/mock_data.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/mock_menu_repository.dart';
import 'data/repositories/mock_order_repository.dart';
import 'data/repositories/mock_store_repository.dart';
import 'data/supabase/supabase_auth_repository.dart';
import 'data/supabase/supabase_menu_repository.dart';
import 'data/supabase/supabase_order_repository.dart';
import 'data/supabase/supabase_store_repository.dart';
import 'screens/splash_screen.dart';

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
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    final seedMenuItems = MockData.menuItems();
    final preferencesRepository = SharedPreferencesRepository();

    if (widget.supabaseConfig.isConfigured) {
      final client = Supabase.instance.client;
      controller = AppController(
        authRepository: SupabaseAuthRepository(client: client),
        menuRepository: SupabaseMenuRepository(client: client),
        orderRepository: SupabaseOrderRepository(client: client),
        preferencesRepository: preferencesRepository,
        storeRepository: SupabaseStoreRepository(client: client),
      );
      return;
    }

    controller = AppController(
      authRepository: MockAuthRepository(),
      menuRepository: MockMenuRepository(seedItems: seedMenuItems),
      orderRepository: MockOrderRepository(seedMenuItems: seedMenuItems),
      preferencesRepository: preferencesRepository,
      storeRepository: MockStoreRepository(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Peri Q',
          theme: AppTheme.lightTheme,
          home: SplashScreen(controller: controller),
        );
      },
    );
  }
}
