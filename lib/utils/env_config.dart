import 'dart:io';

/// Reads Firebase configuration from .env file.
/// Keys are kept out of source code to prevent accidental leaks.
class EnvConfig {
  static final Map<String, String> _env = {};

  /// Loads .env file on first access
  static Future<void> _load() async {
    if (_env.isNotEmpty) return; // Already loaded

    final file = File('.env');
    if (!await file.exists()) return;

    final lines = await file.readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final index = trimmed.indexOf('=');
      if (index == -1) continue;
      final key = trimmed.substring(0, index).trim();
      final value = trimmed.substring(index + 1).trim();
      _env[key] = value;
    }
  }

  /// Get a value from .env with a fallback
  static Future<String> get(String key, {String fallback = ''}) async {
    await _load();
    return _env[key] ?? fallback;
  }

  // ─── Web Keys ───
  static Future<String> get webApiKey async =>
      await get('WEB_API_KEY', fallback: '');
  static Future<String> get webAppId async =>
      await get('WEB_APP_ID', fallback: '');
  static Future<String> get webMessagingSenderId async =>
      await get('WEB_MESSAGING_SENDER_ID', fallback: '');
  static Future<String> get webMeasurementId async =>
      await get('WEB_MEASUREMENT_ID', fallback: '');

  // ─── Android Keys ───
  static Future<String> get androidApiKey async =>
      await get('ANDROID_API_KEY', fallback: '');
  static Future<String> get androidAppId async =>
      await get('ANDROID_APP_ID', fallback: '');

  // ─── iOS/macOS Keys ───
  static Future<String> get iosApiKey async =>
      await get('IOS_API_KEY', fallback: '');
  static Future<String> get iosAppId async =>
      await get('IOS_APP_ID', fallback: '');
  static Future<String> get iosBundleId async =>
      await get('IOS_BUNDLE_ID', fallback: 'com.example.diuEvents');

  // ─── Common Keys ───
  static Future<String> get projectId async =>
      await get('PROJECT_ID', fallback: 'diuevents-3ecd4');
  static Future<String> get storageBucket async =>
      await get('STORAGE_BUCKET', fallback: 'diuevents-3ecd4.firebasestorage.app');
  static Future<String> get messagingSenderId async =>
      await get('MESSAGING_SENDER_ID', fallback: '618114582605');
  static Future<String> get databaseUrl async =>
      await get('DATABASE_URL', fallback: '');
}
