import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final _storage = const FlutterSecureStorage();
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _storage.read(key: 'token');
      print('[ApiService] Token for request: ${token != null ? 'exists' : 'not found'}');
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          ...headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? ''
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': responseData['message'] ?? 'Failed to load data: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Connection error: $e'
      };
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

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? ''
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': responseData['message'] ?? 'Request failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Connection error: $e'
      };
    }
  }
}