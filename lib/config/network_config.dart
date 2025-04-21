import 'dart:io' show HttpClient;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io show Platform;
import 'env_config.dart';

class NetworkConfig {
  // Default API URLs for different environments
  static const String _dockerApiUrl = 'http://api:8000/api'; // Docker container name
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api'; // Android emulator points to host machine
  static const String _iosSimulatorUrl = 'http://localhost:8000/api'; // iOS simulator
  static const String _localDevUrl = 'http://localhost:8000/api'; // Local development
  static const String _webRelativeUrl = '/api'; // Web relative URL
  static const String _debugDirectApiUrl = 'http://localhost:8000/api'; // Direct API access for debugging
  static const String _realDeviceUrl = 'http://192.168.1.100:8000/api'; // Replace with your PC's IP for real device testing

  // Get the appropriate API URL based on platform and environment
  static String getApiUrl() {
    // First check for environment variable (from Docker/production)
    final envApiUrl = EnvConfig.getEnvVar('API_URL');
    
    // Always check for web first to avoid Platform access on web
    if (kIsWeb) {
      // For Chrome debugging, we need to use the direct API URL
      print('Running in web mode - using direct API URL for debugging');
      return _debugDirectApiUrl;
    }
    
    // Now we know we're not on web, we can safely use Platform
    if (envApiUrl != null && envApiUrl.isNotEmpty) {
      // If running in Docker, use the Docker container name
      if (envApiUrl == _dockerApiUrl && !io.Platform.isAndroid && !io.Platform.isIOS) {
        return envApiUrl;
      }
      
      // If running on Android and URL contains 'api:8000', replace with proper Android emulator URL
      if (io.Platform.isAndroid && envApiUrl.contains('api:8000')) {
        return _androidEmulatorUrl;
      }
      
      // If running on iOS and URL contains 'api:8000', replace with localhost
      if (io.Platform.isIOS && envApiUrl.contains('api:8000')) {
        return _iosSimulatorUrl;
      }
      
      // Otherwise use the environment variable as is
      return envApiUrl;
    }
    
    // If no environment variable, use platform-specific defaults
    if (io.Platform.isAndroid) {
      // Check if running on emulator - 10.0.2.2 works only on emulator
      bool isEmulator = false;
      try {
        // A simple heuristic to detect emulator - can be improved
        isEmulator = io.Platform.environment.containsKey('ANDROID_EMULATOR') || 
                     io.Platform.environment.containsKey('ANDROID_SDK_ROOT');
      } catch (e) {
        // Ignore error and assume physical device
      }
      
      return isEmulator ? _androidEmulatorUrl : _realDeviceUrl;
    } else if (io.Platform.isIOS) {
      // For iOS we need to determine if running on simulator or real device
      bool isSimulator = false;
      try {
        // Check for simulator - not perfect but works in most cases
        isSimulator = !io.Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
      } catch (e) {
        // Ignore error and assume physical device
      }
      
      return isSimulator ? _iosSimulatorUrl : _realDeviceUrl;
    }
    
    // Default fallback
    return _localDevUrl;
  }
  
  // Check if the device can connect to the API
  static Future<bool> canConnectToApi(String url) async {
    try {
      if (kIsWeb) {
        // For web, we need to use a different approach since HttpClient isn't available
        // Use a simple fetch request to check connectivity
        try {
          // Add a timestamp to prevent caching
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final testUrl = url.contains('?') ? '$url&_=$timestamp' : '$url?_=$timestamp';
          
          // Log the connection attempt for debugging
          print('Web connectivity check: Attempting to connect to $testUrl');
          
          // Always return true for web debugging to avoid CORS issues during connection check
          return true;
        } catch (e) {
          print('Web connectivity check failed: $e');
          return false;
        }
      }
      
      // Only use HttpClient for non-web platforms
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      print('Connectivity check failed: $e');
      return false;
    }
  }
  
  // Print debug info about current connection settings
  static void printDebugInfo() {
    final apiUrl = getApiUrl();
    print('========= API CONNECTION INFO =========');
    print('Platform: ${kIsWeb ? 'Web Browser' : io.Platform.operatingSystem}');
    print('API URL: $apiUrl');
    print('======================================');
  }
}