import 'dart:io' show Platform;

class Constants {
  // Use 10.0.2.2 for Android emulator to reach localhost, 127.0.0.1 for iOS
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }
}
