import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:handy_app/firebase_options.dart';

abstract final class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get isConfigured => DefaultFirebaseOptions.isConfigured;

  static bool get isInitialized => _initialized;

  static Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    if (!isConfigured) {
      return false;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      return true;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
