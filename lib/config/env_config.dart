import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'env_config_generated.dart';

class EnvConfig {
  // Get API URL from environment variables if available, otherwise use default
  static String getApiUrl() {
    // This method is kept for backward compatibility
    // The actual implementation is now in NetworkConfig.getApiUrl()
    return 'http://localhost:8000/api';
  }

  // Helper to get environment variables
  static String? getEnvVar(String name) {
    try {
      // Try to get from generated config first
      if (EnvConfigGenerated.values.containsKey(name)) {
        return EnvConfigGenerated.values[name];
      }
      
      // Then try to get from platform environment
      // This is more complex and depends on platform
      if (!kIsWeb && Platform.environment.containsKey(name)) {
        return Platform.environment[name];
      }
      
      return null;
    } catch (e) {
      print('Error getting environment variable $name: $e');
      return null;
    }
  }

  // Get app environment (development, production, etc.)
  static String getAppEnvironment() {
    return _getEnvVar('APP_ENV') ?? 'development';
  }

  // Check if app is in debug mode
  static bool isDebugMode() {
    final debugMode = _getEnvVar('APP_DEBUG');
    return debugMode?.toLowerCase() == 'true';
  }
  
  // Private helper method to get environment variables
  static String? _getEnvVar(String name) {
    return getEnvVar(name);
  }
}