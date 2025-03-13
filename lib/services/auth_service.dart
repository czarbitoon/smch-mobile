import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8000/api';
  final _storage = const FlutterSecureStorage();
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

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
      final error = json.decode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Authentication failed'};
    } catch (e) {
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    }
  }

  void _logError(String method, dynamic error) {
    print('[AuthService] $method error: $error');
  }
}