import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseConfig = SupabaseConfig.fromEnvironment();

  if (supabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: supabaseConfig.url,
      anonKey: supabaseConfig.publishableKey,
    );
  }

  runApp(PeriQApp(supabaseConfig: supabaseConfig));
}
