import 'package:flutter/foundation.dart' show kIsWeb;

// For non-web platforms
import 'dart:io' show Platform;

class AppConfig {
  // Base URL for API requests
  // Default for Android emulator: 10.0.2.2 (special IP that connects to host machine)
  // Default for iOS simulator: localhost
  // For web: localhost or the actual domain where the backend is hosted
  // For physical devices: Use the actual IP address or hostname of your backend server
  static String get apiBaseUrl {
    if (kIsWeb) {
      // For web platform
      return 'http://localhost:8000/api'; // Web
    } else {
      // For native platforms
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8000/api'; // Android emulator
        } else if (Platform.isIOS) {
          return 'http://localhost:8000/api'; // iOS simulator
        }
      } catch (e) {
        // Handle case where Platform is not available
      }
      // For other platforms or if Platform check fails
      return 'http://localhost:8000/api';
    }
  }

  // Timeout duration for API requests
  static const Duration apiTimeout = Duration(seconds: 30);

  // Cache duration for data
  static const Duration cacheDuration = Duration(hours: 24);

  // App version
  static const String appVersion = '1.0.0';
}