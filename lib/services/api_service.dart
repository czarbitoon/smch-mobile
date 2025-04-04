import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  final _storage = const FlutterSecureStorage();
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}').replace(queryParameters: queryParams);
      
      // Use appropriate headers based on whether the endpoint is protected or not
      final requestHeaders = _isUnprotectedEndpoint(endpoint) ? headers : await _getHeaders();
      
      final response = await http.get(
        uri,
        headers: requestHeaders,
      );
      return _handleResponse(response);
    } on FormatException catch (e) {
      _logError('GET', e);
      return _formatError();
    } catch (e) {
      _logError('GET', e);
      if (e is UnauthorizedException) {
        return {'success': false, 'message': e.toString()};
      }
      return _connectionError();
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      return _handleResponse(response);
    } on FormatException catch (e) {
      _logError('POST', e);
      return _formatError();
    } catch (e) {
      _logError('POST', e);
      return _connectionError();
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, dynamic body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on FormatException catch (e) {
      _logError('PUT', e);
      return _formatError();
    } catch (e) {
      _logError('PUT', e);
      return _connectionError();
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } on FormatException catch (e) {
      _logError('DELETE', e);
      return _formatError();
    } catch (e) {
      _logError('DELETE', e);
      return _connectionError();
    }
  }

  Future<Map<String, dynamic>> patch(String endpoint, dynamic body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on FormatException catch (e) {
      _logError('PATCH', e);
      return _formatError();
    } catch (e) {
      _logError('PATCH', e);
      return _connectionError();
    }
  }

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw UnauthorizedException('No token found');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Check if endpoint is unprotected and doesn't require authentication
  bool _isUnprotectedEndpoint(String endpoint) {
    // List of endpoints that don't require authentication
    final unprotectedEndpoints = [
      'offices',
      'device-categories',
      'device-categories/',
      'device-types/'
    ];
    
    // Normalize the endpoint by removing leading slash
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    
    // Check if the endpoint is in the unprotected list or starts with any of the unprotected prefixes
    return unprotectedEndpoints.any((e) => normalizedEndpoint == e || normalizedEndpoint.startsWith(e));
  }

  void _logError(String method, dynamic error) {
    print('[ApiService] $method error: $error');
  }

  Map<String, dynamic> _connectionError() {
    return {'success': false, 'message': 'Connection error', 'status': 503};
  }

  Map<String, dynamic> _formatError() {
    return {'success': false, 'message': 'Invalid data format', 'status': 400};
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final dynamic responseData = json.decode(response.body);

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return _unauthorizedError();
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _successResponse(responseData);
      }

      if (responseData is Map<String, dynamic>) {
        return _errorResponse(response.statusCode, responseData);
      } else {
        return {
          'success': false,
          'message': 'Request failed with status $response.statusCode',
          'status': response.statusCode
        };
      }
    } catch (e) {
      _logError('Response handling', e);
      return _processError(response.statusCode);
    }
  }

  void _handleUnauthorized() {
    print('[ApiService] Received 401 unauthorized response');
    _storage.deleteAll();
  }

  Map<String, dynamic> _unauthorizedError() {
    return {
      'success': false,
      'message': 'Session expired: Please log in again',
      'status': 401
    };
  }

  Map<String, dynamic> _successResponse(dynamic responseData) {
    if (responseData is List) {
      return {
        'success': true,
        'data': responseData,
        'message': '',
        'reports': responseData
      };
    }
    
    final data = responseData as Map<String, dynamic>;
    return {
      'success': true,
      'data': data['data'] ?? data,
      'message': data['message'] ?? '',
      'reports': data['data'] ?? data['reports'] ?? []
    };
  }

  Map<String, dynamic> _errorResponse(int statusCode, Map<String, dynamic> data) {
    if (statusCode == 422) {
      return {
        'success': false,
        'message': data['message'] ?? 'Validation failed',
        'status': statusCode,
        'errors': data['errors'] ?? {}
      };
    }
    return {
      'success': false,
      'message': data['message'] ?? 'Request failed with status $statusCode',
      'status': statusCode
    };
  }

  Map<String, dynamic> _processError(int statusCode) {
    return {
      'success': false,
      'message': 'Failed to process response',
      'status': statusCode
    };
  }
}