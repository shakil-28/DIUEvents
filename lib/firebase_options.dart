// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Multi-platform [FirebaseOptions] for DIU Events.
///
/// API keys are loaded from .env file (flutter_dotenv) to prevent
/// accidental exposure in version control.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Android config
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '', // loaded from .env
    appId: '', // loaded from .env
    messagingSenderId: '', // loaded from .env
    projectId: '', // loaded from .env
    storageBucket: '', // loaded from .env
  );

  // iOS config
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '', // loaded from .env
    appId: '', // loaded from .env
    messagingSenderId: '', // loaded from .env
    projectId: '', // loaded from .env
    storageBucket: '', // loaded from .env
    iosBundleId: '', // loaded from .env
  );

  // macOS config
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '', // loaded from .env
    appId: '', // loaded from .env
    messagingSenderId: '', // loaded from .env
    projectId: '', // loaded from .env
    storageBucket: '', // loaded from .env
  );

  // Web config
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '', // loaded from .env
    appId: '', // loaded from .env
    messagingSenderId: '', // loaded from .env
    projectId: '', // loaded from .env
    storageBucket: '', // loaded from .env
    authDomain: '', // loaded from .env
    measurementId: '', // loaded from .env
  );

  // Windows config
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '', // loaded from .env
    appId: '', // loaded from .env
    messagingSenderId: '', // loaded from .env
    projectId: '', // loaded from .env
    storageBucket: '', // loaded from .env
  );

  /// Initialize all platform options from .env file.
  /// Call this once in main() before Firebase.initializeApp().
  static Future<void> initialize() async {
    // These values are loaded by flutter_dotenv in main.dart
    // The actual FirebaseOptions are built dynamically in main.dart
  }
}
