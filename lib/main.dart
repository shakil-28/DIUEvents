import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

/// Platform-safe Firebase initialization.
Future<void> _ensureFirebase() async {
  if (kIsWeb) return;
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return;
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (gitignored, contains real API keys)
  await dotenv.load(fileName: '.env');

  // Determine platform
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

  // Get keys based on platform
  String apiKey;
  String appId;

  if (isAndroid) {
    apiKey = dotenv.get('FIREBASE_ANDROID_API_KEY');
    appId = dotenv.get('FIREBASE_ANDROID_APP_ID');
  } else if (isIOS || isMacOS) {
    apiKey = dotenv.get('FIREBASE_IOS_API_KEY');
    appId = dotenv.get('FIREBASE_IOS_APP_ID');
  } else {
    apiKey = dotenv.get('FIREBASE_WEB_API_KEY');
    appId = dotenv.get('FIREBASE_WEB_APP_ID');
  }

  final senderId = dotenv.get('FIREBASE_MESSAGING_SENDER_ID');
  final projectId = dotenv.get('FIREBASE_PROJECT_ID');
  final storageBucket = dotenv.get('FIREBASE_STORAGE_BUCKET');

  FirebaseOptions firebaseOptions;

  if (kIsWeb) {
    firebaseOptions = FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      storageBucket: storageBucket,
      measurementId: dotenv.get('FIREBASE_WEB_MEASUREMENT_ID'),
      authDomain: '$projectId.firebaseapp.com',
    );
  } else if (isIOS || isMacOS) {
    firebaseOptions = FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
    );
  } else {
    firebaseOptions = FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }

  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DIU Events',
      themeMode: _themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: SplashScreen(setThemeMode: setThemeMode),
    );
  }

  // ── Light theme ──────────────────────────────────────────────
  static final _lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
    buttonTheme: const ButtonThemeData(buttonColor: Colors.black),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.black).copyWith(
      surfaceContainerHighest: Colors.grey.shade100,
      onSurface: Colors.black,
    ),
  );

  // ── Dark theme ───────────────────────────────────────────────
  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0E11),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF16181D),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
    buttonTheme: const ButtonThemeData(buttonColor: Color(0xFF1A1A1A)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1A1A1A),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A1A1A),
      brightness: Brightness.dark,
    ).copyWith(
      surfaceContainerHighest: const Color(0xFF16181D),
      onSurface: Colors.white,
    ),
  );
}
