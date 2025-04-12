import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class AuthService {
  // Get base URL from AppConfig
  String get baseUrl => AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();
  final Dio _dio;
  
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  
  AuthService() : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final userStr = await _storage.read(key: 'user');
      if (userStr == null) return null;

      final userData = await _parseUserData(userStr);
      return userData;
    } catch (e) {
      _logError('getCurrentUser', e);
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final tokenResponse = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (tokenResponse.statusCode != 200) {
        await _storage.deleteAll();
        return _handleErrorResponse(tokenResponse);
      }

      final tokenData = json.decode(tokenResponse.body);
      final token = tokenData['token'];
      await _storage.write(key: 'token', value: token);

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        return _handleErrorResponse(response);
      }

      return await _handleLoginSuccess(response);
    } catch (e) {
      return _handleLoginError(e);
    }
  }

  Future<bool> logout() async {
    try {
      final token = await _getToken();
      if (token == null) return true;

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );

      await _storage.deleteAll();
      return response.statusCode == 200;
    } catch (e) {
      _logError('logout', e);
      return false;
    }
  }

  Future<String?> getToken() async => _getToken();

  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  // Private helper methods
  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> _parseUserData(String userStr) async {
    try {
      final userData = json.decode(userStr) as Map<String, dynamic>;
      if (!userData.containsKey('type')) {
        _logError('parseUserData', 'Missing type field');
        return null;
      }
      return userData;
    } catch (e) {
      _logError('parseUserData', e);
      return null;
    }
  }

  Future<Map<String, dynamic>> _handleLoginSuccess(http.Response response) async {
    try {
      final data = json.decode(response.body);
      final token = data['access_token'] ?? data['token'];
      final userType = data['type'];

      if (token == null || userType == null) {
        return {'success': false, 'message': 'Invalid server response'};
      }

      final userData = {
        'type': userType,
        'office_id': data['office_id']
      };

      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'user', value: json.encode(userData));

      return {'success': true, 'user': userData};
    } catch (e) {
      _logError('handleLoginSuccess', e);
      return {'success': false, 'message': 'Failed to process login response'};
    }
  }

  Map<String, dynamic> _handleLoginError(dynamic error) {
    if (error is FormatException) {
      return {'success': false, 'message': 'Invalid server response format'};
    }
    return {'success': false, 'message': 'Connection error: Unable to reach the server'};
  }

  Map<String, dynamic> _handleErrorResponse(http.Response response) {
    try {
      final responseBody = json.decode(response.body);
      
      // Check for validation errors structure
      if (responseBody.containsKey('errors') && responseBody['errors'] is Map) {
        final errors = responseBody['errors'] as Map;
        
        // Check specifically for email validation errors
        if (errors.containsKey('email')) {
          final emailErrors = errors['email'] as List;
          if (emailErrors.isNotEmpty) {
            // If there's a specific email error, prioritize showing it clearly
            return {'success': false, 'message': 'Email error: ${emailErrors.join(', ')}'};
          }
        }
        
        // Format all validation errors into a readable message
        final errorMessages = errors.entries
            .map((e) => '${e.key}: ${(e.value as List).join(', ')}')
            .join('\n');
        return {'success': false, 'message': 'Validation failed:\n$errorMessages'};
      }
      
      // Check for error message
      if (responseBody.containsKey('error')) {
        return {'success': false, 'message': responseBody['error']};
      }
      
      // Fallback to message or default
      return {'success': false, 'message': responseBody['message'] ?? 'Authentication failed'};
    } catch (e) {
      _logError('handleErrorResponse', e);
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    }
  }

  void _logError(String method, dynamic error) {
    print('[AuthService] $method error: $error');
  }

  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      
      // Handle different response structures
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data['data'] is Map<String, dynamic>) {
          // If data['data'] is a map that contains a 'devices' list
          final devicesData = data['data']['devices'];
          if (devicesData is List) {
            return List<Map<String, dynamic>>.from(devicesData);
          }
        } else if (data['devices'] is List) {
          // Direct 'devices' field in response
          return List<Map<String, dynamic>>.from(data['devices']);
        }
      }
      
      // Fallback to empty list if structure doesn't match expected format
      return [];
    } catch (e) {
      _logError('getDevices', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      
      // Handle different response structures
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data['data'] is Map<String, dynamic>) {
          // If data['data'] is a map that contains a 'reports' list
          final reportsData = data['data']['reports'];
          if (reportsData is List) {
            return List<Map<String, dynamic>>.from(reportsData);
          }
        } else if (data['reports'] is List) {
          // Direct 'reports' field in response
          return List<Map<String, dynamic>>.from(data['reports']);
        }
      }
      
      // Fallback to empty list if structure doesn't match expected format
      return [];
    } catch (e) {
      _logError('getReports', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOffices() async {
    try {
      // Create an instance of ApiService which properly handles unprotected endpoints
      final apiService = ApiService(baseUrl: AppConfig.apiUrl);
      
      // Use ApiService to make the request to the unprotected offices endpoint
      final response = await apiService.get('offices');
      
      if (!response['success']) {
        _logError('getOffices', 'API returned error: ${response['message']}');
        return [];
      }
      
      // Extract offices data from the response
      final data = response['data'];
      _logError('getOffices', 'Response data: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
      
      // Handle different response structures
      if (data is List) {
        // Direct list of offices
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          // If data['data'] is a list of offices
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data['data'] is Map<String, dynamic>) {
          // If data['data'] is a map that contains an 'offices' list
          final officesData = data['data']['offices'];
          if (officesData is List) {
            return List<Map<String, dynamic>>.from(officesData);
          }
        } else if (data['offices'] is List) {
          // Direct 'offices' field in response
          return List<Map<String, dynamic>>.from(data['offices']);
        }
      }
      
      // Fallback to empty list if structure doesn't match expected format
      _logError('getOffices', 'Could not parse response format');
      return [];
    } catch (e) {
      _logError('getOffices', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, int type, String officeId) async {
    try {
      // Validate input parameters
      if (name.isEmpty || email.isEmpty || password.isEmpty || officeId.isEmpty) {
        return {'success': false, 'message': 'All fields are required'};
      }

      // Log the request payload for debugging
      final payload = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'type': type,
        'office_id': officeId,
      };
      _logError('register', 'Sending request with payload: $payload');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: json.encode(payload),
      );

      // Log the response for debugging
      _logError('register', 'Response status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode != 201) {
        // Handle validation errors specifically for registration
        if (response.statusCode == 422) {
          try {
            final responseBody = json.decode(response.body);
            if (responseBody.containsKey('errors')) {
              final errors = responseBody['errors'] as Map;
              
              // Check specifically for email validation errors
              if (errors.containsKey('email')) {
                final emailErrors = errors['email'] as List;
                if (emailErrors.isNotEmpty) {
                  // If there's a specific email error, prioritize showing it clearly
                  return {'success': false, 'message': 'Email error: ${emailErrors.join(', ')}'};
                }
              }
              
              // Return all validation errors
              return {'success': false, 'message': 'Validation failed', 'errors': errors};
            }
          } catch (e) {
            _logError('register', 'Error parsing validation errors: $e');
          }
        }
        
        // Use the general error handler for other error types
        return _handleErrorResponse(response);
      }

      // Parse successful response
      final responseData = json.decode(response.body);
      return {
        'success': true,
        'message': responseData['message'] ?? 'Registration successful',
        'data': responseData
      };
    } catch (e) {
      _logError('register', e);
      return {'success': false, 'message': 'Registration failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};


      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Failed to fetch profile'};
      }

      final data = json.decode(response.body);
      return {'success': true, 'data': data};
    } catch (e) {
      _logError('getUserProfile', e);
      return {'success': false, 'message': 'Error fetching profile: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.post(
        Uri.parse('$baseUrl/profile/update'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(profileData),
      );

      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Failed to update profile'};
      }

      final data = json.decode(response.body);
      return {'success': true, 'data': data};
    } catch (e) {
      _logError('updateUserProfile', e);
      return {'success': false, 'message': 'Error updating profile: ${e.toString()}'};
    }
  }

  Future<void> _handleLogout() async {
    try {
      final apiService = ApiService(baseUrl: AppConfig.apiUrl);
      await apiService.post('auth/logout', {});
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(int userId, String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });
      
      final response = await _dio.post(
        'users/$userId/profile-image',
        data: formData,
      );
      
      return response.data;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}