import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseConfig = SupabaseConfig.fromSources();

  if (supabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: supabaseConfig.url,
      publishableKey: supabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  runApp(PeriQApp(supabaseConfig: supabaseConfig));
}
