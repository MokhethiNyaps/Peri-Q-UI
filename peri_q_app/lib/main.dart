import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/supabase_config.dart';
import 'src/data/local/secure_auth_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  final supabaseConfig = SupabaseConfig.fromSources();

  if (supabaseConfig.isConfigured) {
    final sessionKey =
        'sb-${Uri.parse(supabaseConfig.url).host.split('.').first}-auth-token';
    await Supabase.initialize(
      url: supabaseConfig.url,
      publishableKey: supabaseConfig.publishableKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureAuthLocalStorage(sessionKey: sessionKey),
        pkceAsyncStorage: SecurePkceStorage(),
      ),
    );
  }

  runApp(PeriQApp(supabaseConfig: supabaseConfig));
}
