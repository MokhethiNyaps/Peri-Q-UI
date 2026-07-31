import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/supabase_config.dart';
import 'src/data/local/secure_auth_storage.dart';
import 'src/data/notifications/firebase_push_notification_service.dart';
import 'src/repositories/notification_repository.dart';

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
  var firebaseIsReady = false;

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    firebaseIsReady = true;
  } catch (_) {
    // Push notification startup must never prevent ordering from launching.
  }

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

  NotificationRepository notificationRepository =
      const NoopNotificationRepository();
  if (firebaseIsReady && supabaseConfig.isConfigured) {
    try {
      notificationRepository = await FirebasePushNotificationService.initialize(
        client: Supabase.instance.client,
      );
    } catch (_) {
      // Existing app functionality remains available if notification
      // permission, device services, or local notification setup fails.
    }
  }

  runApp(
    PeriQApp(
      supabaseConfig: supabaseConfig,
      notificationRepository: notificationRepository,
    ),
  );
}
