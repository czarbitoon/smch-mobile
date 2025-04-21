import 'dart:io' show HttpClient, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';
import '../config/network_config.dart';

/// A utility class for diagnosing API connection issues
class ApiDiagnostics {
  /// Runs a comprehensive API connection test and returns diagnostic information
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnosticResults = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': _getPlatformInfo(),
      'api_configuration': {
        'configured_url': AppConfig.apiUrl,
        'network_config_url': NetworkConfig.getApiUrl(),
      },
      'connection_tests': <Map<String, dynamic>>[],
    };

    // Test the configured API URL
    final configuredUrlTest = await _testApiEndpoint(
      AppConfig.apiUrl,
      'Configured API URL',
    );
    diagnosticResults['connection_tests'].add(configuredUrlTest);

    // Test alternative URLs based on platform
    if (Platform.isAndroid) {
      // Test Android emulator URL
      final emulatorTest = await _testApiEndpoint(
        'http://10.0.2.2:8000/api',
        'Android Emulator URL',
      );
      diagnosticResults['connection_tests'].add(emulatorTest);
    }

    // Test localhost
    final localhostTest = await _testApiEndpoint(
      'http://localhost:8000/api',
      'Localhost URL',
    );
    diagnosticResults['connection_tests'].add(localhostTest);

    // Determine the best URL to use
    final workingUrls = diagnosticResults['connection_tests']
        .where((test) => test['success'] == true)
        .toList();

    diagnosticResults['recommendation'] = workingUrls.isNotEmpty
        ? 'Use ${workingUrls.first['url']} for API connections'
        : 'No working API URLs found. Check that the backend server is running and accessible.';

    return diagnosticResults;
  }

  /// Tests a specific API endpoint and returns the results
  static Future<Map<String, dynamic>> _testApiEndpoint(
    String url,
    String description,
  ) async {
    final result = <String, dynamic>{
      'url': url,
      'description': description,
      'success': false,
      'status_code': null,
      'error': null,
      'response_time_ms': 0,
    };

    try {
      final stopwatch = Stopwatch()..start();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final uri = Uri.parse('$url/offices'); // Test the offices endpoint
      final request = await client.getUrl(uri);
      final response = await request.close();
      stopwatch.stop();

      result['success'] = response.statusCode >= 200 && response.statusCode < 400;
      result['status_code'] = response.statusCode;
      result['response_time_ms'] = stopwatch.elapsedMilliseconds;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Gets information about the current platform
  static Map<String, dynamic> _getPlatformInfo() {
    if (kIsWeb) {
      return {'type': 'web'};
    } else if (Platform.isAndroid) {
      return {
        'type': 'android',
        'is_emulator': _isEmulator(),
      };
    } else if (Platform.isIOS) {
      return {
        'type': 'ios',
        'is_simulator': _isSimulator(),
      };
    } else if (Platform.isWindows) {
      return {'type': 'windows'};
    } else if (Platform.isLinux) {
      return {'type': 'linux'};
    } else if (Platform.isMacOS) {
      return {'type': 'macos'};
    } else {
      return {'type': 'unknown'};
    }
  }

  /// Attempts to determine if running on an Android emulator
  static bool _isEmulator() {
    try {
      if (Platform.isAndroid) {
        // This is a simple heuristic - emulators often use 10.0.2.2 for localhost
        return true; // For simplicity, we'll assume emulator in diagnostic context
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to determine if running on an iOS simulator
  static bool _isSimulator() {
    try {
      if (Platform.isIOS) {
        // For simplicity, we'll assume simulator in diagnostic context
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}