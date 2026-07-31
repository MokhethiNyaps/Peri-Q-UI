import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order.dart';
import '../../repositories/notification_repository.dart';

const _adminChannel = AndroidNotificationChannel(
  'admin_orders',
  'Admin order alerts',
  description: 'Immediate alerts for newly placed customer orders.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const _clientChannel = AndroidNotificationChannel(
  'client_order_updates',
  'Order status updates',
  description: 'Important updates about the progress of your order.',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payloads are displayed by Android/iOS while backgrounded or
  // terminated. The handler remains registered for data payload processing.
}

class FirebasePushNotificationService implements NotificationRepository {
  FirebasePushNotificationService._({
    required this._client,
    required this._messaging,
    required this._localNotifications,
    required this._secureStorage,
  });

  static const _installationIdKey = 'peri_q_push_installation_id';

  final SupabaseClient _client;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FlutterSecureStorage _secureStorage;

  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  StreamSubscription<String>? _tokenRefreshes;
  String? _currentUserId;
  bool _currentUserIsAdmin = false;
  bool _isDisposed = false;

  static Future<FirebasePushNotificationService> initialize({
    required SupabaseClient client,
  }) async {
    final service = FirebasePushNotificationService._(
      client: client,
      messaging: FirebaseMessaging.instance,
      localNotifications: FlutterLocalNotificationsPlugin(),
      secureStorage: const FlutterSecureStorage(),
    );
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_peri_q'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(settings: initializationSettings);

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_adminChannel);
    await androidNotifications?.createNotificationChannel(_clientChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundMessages = FirebaseMessaging.onMessage.listen(
      (message) =>
          unawaited(_showForegroundNotification(message).catchError((_) {})),
      onError: (_) {},
    );
    _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedNotification,
      onError: (_) {},
    );
    _tokenRefreshes = _messaging.onTokenRefresh.listen(
      (token) => unawaited(_handleTokenRefresh(token).catchError((_) {})),
      onError: (_) {},
    );

    await requestPermission();
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedNotification(initialMessage);
    }
  }

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> registerForSession({
    required String userId,
    required bool isAdmin,
  }) async {
    if (_isDisposed) {
      return;
    }
    _currentUserId = userId;
    _currentUserIsAdmin = isAdmin;
    if (!await requestPermission()) {
      return;
    }
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (_currentUserId == null || token.isEmpty || _isDisposed) {
      return;
    }
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    await _client.rpc(
      'register_push_token',
      params: {
        'p_installation_id': await _installationId(),
        'p_fcm_token': token,
        'p_role': _currentUserIsAdmin ? 'admin' : 'client',
        'p_platform': _platformName,
      },
    );
  }

  @override
  Future<void> unregisterCurrentSession() async {
    if (_currentUserId == null || _isDisposed) {
      return;
    }
    try {
      await _client.rpc(
        'unregister_push_token',
        params: {'p_installation_id': await _installationId()},
      );
    } finally {
      _currentUserId = null;
      _currentUserIsAdmin = false;
    }
  }

  @override
  Future<void> notifyNewOrder(OrderModel order) {
    return _invokeNotificationFunction(event: 'new_order', orderId: order.id);
  }

  @override
  Future<void> notifyOrderStatusChanged(OrderModel order) {
    return _invokeNotificationFunction(
      event: 'status_update',
      orderId: order.id,
    );
  }

  Future<void> _invokeNotificationFunction({
    required String event,
    required String orderId,
  }) async {
    if (_isDisposed || _client.auth.currentSession == null) {
      return;
    }
    await _client.functions.invoke(
      'order-push',
      body: {'event': event, 'order_id': orderId},
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // Apple foreground presentation is handled by
      // setForegroundNotificationPresentationOptions above.
      return;
    }

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) {
      return;
    }

    final channel = _channelFor(message);
    await _localNotifications.show(
      id:
          (message.messageId?.hashCode ??
                  DateTime.now().millisecondsSinceEpoch.hashCode)
              .abs(),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: 'ic_stat_peri_q',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  AndroidNotificationChannel _channelFor(RemoteMessage message) {
    final channelId =
        message.data['channel_id'] as String? ??
        message.notification?.android?.channelId;
    return channelId == _adminChannel.id ? _adminChannel : _clientChannel;
  }

  void _handleOpenedNotification(RemoteMessage message) {
    // The operating system opens the app. Existing Supabase realtime streams
    // then refresh the relevant order data without changing navigation/state.
  }

  Future<String> _installationId() async {
    final existing = await _secureStorage.read(key: _installationIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final generated = base64UrlEncode(bytes).replaceAll('=', '');
    await _secureStorage.write(key: _installationIdKey, value: generated);
    return generated;
  }

  String get _platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unsupported',
    };
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_foregroundMessages?.cancel());
    unawaited(_openedMessages?.cancel());
    unawaited(_tokenRefreshes?.cancel());
  }
}
