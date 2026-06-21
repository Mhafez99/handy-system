import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for Handy.
///
/// By default values come from `--dart-define-from-file=config/backend.json`.
/// You can replace this file by running:
/// `dart pub global run flutterfire_cli:flutterfire configure`
class DefaultFirebaseOptions {
  static bool get isConfigured {
    return firebaseProjectId.isNotEmpty &&
        firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty;
  }

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web yet.');
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase is not configured for $defaultTargetPlatform.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    storageBucket: firebaseStorageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    storageBucket: firebaseStorageBucket,
    iosBundleId: 'com.handyapp.handyApp',
  );
}
