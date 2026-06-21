import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/core/firebase/firebase_bootstrap.dart';
import 'package:handy_app/core/refresh/app_refresh_bus.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.initialize();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  bool _initialized = false;

  static String? get currentToken => _currentToken;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    if (!BackendConfig.isApiConfigured || !FirebaseBootstrap.isConfigured) {
      return;
    }

    final firebaseReady = await FirebaseBootstrap.initialize();
    if (!firebaseReady) {
      return;
    }

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final authorized =
        permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      debugPrint('Push notifications permission was not granted.');
      return;
    }

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final token = await messaging.getToken();
    if (token != null) {
      await registerToken(token);
    }

    _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen(registerToken);
    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      (message) => handleForegroundData(message.data),
    );
    _openedAppSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => handleForegroundData(message.data),
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      handleForegroundData(initialMessage.data);
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _initialized = false;
  }

  Future<void> registerToken(String token) async {
    if (!BackendConfig.isApiConfigured || token.trim().isEmpty) {
      return;
    }

    _currentToken = token.trim();
    await HandyApi().devices.registerToken(
      token: _currentToken!,
      platform: _currentPlatform(),
    );
  }

  Future<void> unregisterCurrentToken() async {
    final token = _currentToken;
    if (token == null || !BackendConfig.isApiConfigured) {
      _currentToken = null;
      return;
    }

    try {
      await HandyApi().devices.unregisterToken(token);
    } catch (error) {
      debugPrint('Failed to unregister device token: $error');
    } finally {
      _currentToken = null;
    }

    await dispose();
  }

  void handleForegroundData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type is String && type.isNotEmpty) {
      AppRefreshBus.instance.notify();
    }
  }

  String _currentPlatform() {
    if (kIsWeb) {
      return 'web';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return 'android';
  }
}
