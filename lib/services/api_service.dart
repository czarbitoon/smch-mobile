import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:retry/retry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/cache_manager.dart';
import '../config/app_config.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _cacheManager = CacheManager();
  final _connectivity = Connectivity();
  final _requestQueue = <Future Function()>[];
  Timer? _batchTimer;
  bool _isProcessingQueue = false;
  bool _isOnline = true;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_URL'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ));

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Initialize cache and check connectivity
    await _cacheManager.initialize();
    _isOnline = await _checkConnectivity();
    _setupConnectivityListener();
  }

  Future<bool> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _processPendingRequests();
      }
    });
  }

  Future<void> _processPendingRequests() async {
    final pendingActions = await _cacheManager.getPendingActions();
    for (final action in pendingActions) {
      try {
        switch (action['method']) {
          case 'POST':
            await post(
              action['endpoint'],
              json.decode(action['data']),
              skipOfflineQueue: true,
            );
            break;
          case 'PUT':
            await put(
              action['endpoint'],
              json.decode(action['data']),
              skipOfflineQueue: true,
            );
            break;
          case 'DELETE':
            await delete(
              action['endpoint'],
              skipOfflineQueue: true,
            );
            break;
        }
      } catch (e) {
        debugPrint('Error processing pending request: $e');
      }
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool forceRefresh = false,
    Duration? maxAge,
  }) async {
    if (!_isOnline) {
      final cachedData = await _cacheManager.get<T>(path);
      if (cachedData != null) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: cachedData,
          statusCode: 200,
        );
      }
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection and no cached data available',
      );
    }

    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      await _cacheManager.set(path, response.data, maxAge: maxAge);
      return response;
    } catch (e) {
      final cachedData = await _cacheManager.get<T>(path);
      if (cachedData != null) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: cachedData,
          statusCode: 200,
        );
      }
      rethrow;
    }
  }

  Future<Response> post(
    String path,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipOfflineQueue = false,
  }) async {
    if (!_isOnline && !skipOfflineQueue) {
      await _cacheManager.savePendingAction('POST', path, data);
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {'message': 'Request queued for offline processing'},
        statusCode: 202,
      );
    }

    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipOfflineQueue = false,
  }) async {
    if (!_isOnline && !skipOfflineQueue) {
      await _cacheManager.savePendingAction('PUT', path, data);
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {'message': 'Request queued for offline processing'},
        statusCode: 202,
      );
    }

    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipOfflineQueue = false,
  }) async {
    if (!_isOnline && !skipOfflineQueue) {
      await _cacheManager.savePendingAction('DELETE', path, null);
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {'message': 'Request queued for offline processing'},
        statusCode: 202,
      );
    }

    return _dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> clearCache() => _cacheManager.clear();

  void dispose() {
    _batchTimer?.cancel();
    _requestQueue.clear();
    _cacheManager.dispose();
  }

  // Get base URL from AppConfig
  static String get baseUrl => AppConfig.apiBaseUrl;
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
  
  Future<Map<String, dynamic>> uploadWithImage(String endpoint, Map<String, dynamic> data, String imagePath, {String imageFieldName = 'report_image'}) async {
    try {
      final uri = Uri.parse('$baseUrl${endpoint.startsWith('/') ? endpoint : '/$endpoint'}');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers (excluding content-type as it's set by MultipartRequest)
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // MultipartRequest sets this automatically
      request.headers.addAll(headers);
      
      // Add text fields
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      // Add image file if path is provided
      if (imagePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath(imageFieldName, imagePath);
        request.files.add(file);
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      _logError('UPLOAD', e);
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