import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8000/api';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> getCurrentUser() async {
    print('[AuthService] Getting current user');
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        print('[AuthService] No token found');
        return null;
      }
      final userStr = await _storage.read(key: 'user');
      print('[AuthService] Stored user data found: ${userStr != null}');
      if (userStr != null) {
        try {
          final userData = json.decode(userStr) as Map<String, dynamic>;
          if (!userData.containsKey('type')) {
            print('[AuthService] User data missing type field');
            return null;
          }
          print('[AuthService] Current user type: ${userData['type']}');
          return userData;
        } catch (e) {
          print('[AuthService] Error parsing user data: $e');
          return null;
        }
      }
      print('[AuthService] No user data found');
      return null;
    } catch (e) {
      print('[AuthService] Error getting current user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('[AuthService] Attempting login for email: $email');
    try {
      print('[AuthService] Making HTTP POST request to: $baseUrl/login');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      print('[AuthService] Login response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[AuthService] Login failed with status ${response.statusCode}');
        try {
          final error = json.decode(response.body);
          return {'success': false, 'message': error['message'] ?? 'Authentication failed'};
        } catch (e) {
          return {'success': false, 'message': 'Server error: ${response.statusCode}'};
        }
      }

      print('[AuthService] Login request successful');
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        print('[AuthService] JSON parsing error: $e');
        return {'success': false, 'message': 'Invalid response format'};
      }

      // Check for access_token or token in response
      final token = data['access_token'] ?? data['token'];
      if (token == null) {
        print('[AuthService] Error: No token received in response');
        return {'success': false, 'message': 'Invalid server response: No token received'};
      }

      // Validate user type
      final userType = data['type'];
      if (userType == null) {
        print('[AuthService] Error: User type not found in response');
        return {'success': false, 'message': 'Invalid response: missing user type'};
      }

      // Create user data map
      final userData = {
        'type': userType,
        'office_id': data['office_id']
      };

      print('[AuthService] Token received, storing credentials');
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'user', value: json.encode(userData));
      
      print('[AuthService] Login successful. User type: ${userData['type']}');
      return {'success': true, 'user': userData};
    } catch (e) {
      print('[AuthService] Login error: $e');
      if (e is FormatException) {
        print('[AuthService] JSON parsing error: Invalid response format');
        return {'success': false, 'message': 'Invalid server response format'};
      }
      return {'success': false, 'message': 'Connection error: Unable to reach the server'};
    }
  }

  Future<bool> logout() async {
    print('[AuthService] Attempting logout');
    try {
      final token = await _storage.read(key: 'token');
      print('[AuthService] Found token for logout: ${token != null}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[AuthService] Logout response status: ${response.statusCode}');
      await _storage.deleteAll();
      print('[AuthService] Storage cleared after logout');
      return response.statusCode == 200;
    } catch (e) {
      print('[AuthService] Logout error: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}