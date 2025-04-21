import 'package:flutter/foundation.dart' show kIsWeb;
import 'env_config.dart';
import 'network_config.dart';

// Only import Platform for non-web platforms when needed
// This is handled inside NetworkConfig now

class AppConfig {
  // API Configuration - dynamically determined from environment
  static String get apiUrl => NetworkConfig.getApiUrl();
  
  // Alias for backward compatibility
  static String get apiBaseUrl => apiUrl;

  // Timeout duration for API requests
  static const Duration apiTimeout = Duration(seconds: 30);

  // Cache duration for data
  static const Duration cacheDuration = Duration(hours: 24);

  // App version
  static const String appVersion = '1.0.0';

  static const String appName = 'SMCH Mobile';
  static const String version = '1.0.0';

  // Authentication
  static const int tokenExpirationDays = 30;
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Feature Flags
  static const bool enableNotifications = true;
  static const bool enableOfflineMode = false;
  static const bool enableDebugMode = true;
  
  // Cache Settings
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  
  // Pagination
  static const int defaultPageSize = 10;
  
  // Report Settings
  static const List<String> reportPriorities = ['Low', 'Medium', 'High', 'Critical'];
  static const List<String> reportStatuses = ['Pending', 'In Progress', 'Resolved', 'Closed'];
}