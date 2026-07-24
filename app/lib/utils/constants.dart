import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:io' show Platform;

class Constants {
  static const String _apiEnv = String.fromEnvironment('API_URL');

  // Use defined API_URL if provided, else use emulator/simulator fallbacks in debug mode
  static String get baseUrl {
    if (_apiEnv.isNotEmpty) {
      return _apiEnv;
    }

    if (kReleaseMode) {
      throw StateError(
        'Missing API_URL configuration in release build. '
        'Please build the app using: flutter build <target> --dart-define=API_URL=https://your-api.com'
      );
    }

    // Default emulator/simulator fallback URLs for local debugging only
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }
}
