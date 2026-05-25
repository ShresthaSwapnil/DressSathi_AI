import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Constants {
  // Use 10.0.2.2 for Android emulator to reach localhost, 127.0.0.1 for iOS/Web
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }
}
