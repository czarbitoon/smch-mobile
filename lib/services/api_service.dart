import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  final _storage = const FlutterSecureStorage();
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _storage.read(key: 'token');
      print('[ApiService] Token for request: ${token != null ? 'exists' : 'not found'}');
      
      if (token == null) {
        print('[ApiService] No token found, returning unauthorized error');
        return {
          'success': false,
          'message': 'Unauthorized: Please log in again',
          'status': 401
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('[ApiService] GET error: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'token');
      print('[ApiService] Token for request: ${token != null ? 'exists' : 'not found'}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          ...headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      print('[ApiService] POST error: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, dynamic body) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      print('[ApiService] PUT error: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      print('[ApiService] DELETE error: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 401) {
        print('[ApiService] Received 401 unauthorized response');
        _storage.deleteAll(); // Clear stored credentials
        return {
          'success': false,
          'message': 'Session expired: Please log in again',
          'status': 401
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? ''
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Request failed with status ${response.statusCode}',
        'status': response.statusCode
      };
    } catch (e) {
      print('[ApiService] Error handling response: $e');
      return {
        'success': false,
        'message': 'Failed to process response',
        'status': response.statusCode
      };
    }
  }
}