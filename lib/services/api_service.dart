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
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService(baseUrl: AppConfig.apiUrl);
  // Initialize the service when it's created
  apiService.initialize();
  return apiService;
});

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;
  
  ApiException(this.message, {this.statusCode, this.data});
  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String baseUrl;
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};
  final Connectivity _connectivity = Connectivity();
  bool _isInitialized = false;

  ApiService({
    required this.baseUrl,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: AppConfig.apiTimeout,
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            // Don't add Authorization header here - it will be added in the interceptor
          },
        )) {
    debugPrint('ApiService initialized with baseUrl: $baseUrl');
  }
        
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check network connectivity before making request
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: NetworkException('No internet connection'),
              type: DioExceptionType.connectionError,
            ),
          );
        }
        
        // Add auth token to request
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle common error scenarios
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          debugPrint('API Timeout: ${e.message}');
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: NetworkException('Request timed out. Please try again.'),
              type: e.type,
            ),
          );
        } else if (e.type == DioExceptionType.connectionError) {
          debugPrint('API Connection Error: ${e.message}');
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: NetworkException('Connection error. Please check your internet connection.'),
              type: e.type,
            ),
          );
        } else if (e.response?.statusCode == 401) {
          debugPrint('API Unauthorized: ${e.message}');
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: UnauthorizedException('Session expired. Please login again.'),
              type: e.type,
              response: e.response,
            ),
          );
        }
        
        debugPrint('API Error: ${e.message}');
        return handler.next(e);
      },
      onResponse: (response, handler) {
        // Validate response structure
        _validateResponse(response);
        return handler.next(response);
      },
    ));
    
    _isInitialized = true;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Use retry for GET requests to handle transient network issues
      final response = await retry(
        () => _dio.get(path, queryParameters: queryParameters),
        retryIf: (e) => e is DioException && 
                       (e.type == DioExceptionType.connectionError ||
                        e.type == DioExceptionType.connectionTimeout),
        maxAttempts: 2,
      );
      
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'GET', path);
    } catch (e) {
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, dynamic data) async {
    if (!_isInitialized) await initialize();
    
    try {
      final response = await _dio.post(path, data: data);
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'POST', path);
    } catch (e) {
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(String path, dynamic data) async {
    if (!_isInitialized) await initialize();
    
    try {
      final response = await _dio.put(path, data: data);
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'PUT', path);
    } catch (e) {
      debugPrint('PUT Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    if (!_isInitialized) await initialize();
    
    try {
      final response = await _dio.delete(path);
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'DELETE', path);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(String path, dynamic data) async {
    if (!_isInitialized) await initialize();
    
    try {
      final response = await _dio.patch(path, data: data);
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'PATCH', path);
    } catch (e) {
      debugPrint('PATCH Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFile(String path, String filePath, String fieldName) async {
    if (!_isInitialized) await initialize();
    
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(path, data: formData);
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'UPLOAD', path);
    } catch (e) {
      debugPrint('Upload Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadWithImage(String path, Map<String, dynamic> data, String imagePath) async {
    if (!_isInitialized) await initialize();
    
    try {
      final formData = FormData.fromMap({
        ...data,
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(path, data: formData);
      return _processResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e, 'UPLOAD_WITH_IMAGE', path);
    } catch (e) {
      debugPrint('Upload Error: $e');
      rethrow;
    }
  }
  
  // Process and validate response
  Map<String, dynamic> _processResponse(Response response) {
    if (response.statusCode == null) {
      throw ApiException('Invalid response: Missing status code');
    }
    
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      if (response.data == null) {
        return {'success': true, 'message': 'Operation completed successfully'};
      }
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        try {
          return json.decode(response.data);
        } catch (e) {
          return {'data': response.data, 'success': true};
        }
      } else if (response.data is List) {
        return {'data': response.data, 'success': true};
      }
      
      return {'data': response.data, 'success': true};
    } else if (response.statusCode! >= 400 && response.statusCode! < 500) {
      final errorData = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : {'message': 'Request failed with status: ${response.statusCode}'};
          
      throw ApiException(
        errorData['message'] ?? 'Request failed', 
        statusCode: response.statusCode,
        data: errorData,
      );
    } else {
      throw ApiException('Server error: ${response.statusCode}', statusCode: response.statusCode);
    }
  }
  
  // Validate response structure
  void _validateResponse(Response response) {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      return; // Skip validation for non-success responses
    }
    
    if (response.data == null) {
      debugPrint('Warning: Empty response body');
      return;
    }
    
    if (response.data is! Map<String, dynamic>) {
      return; // Skip validation for non-map responses
    }
    
    final data = response.data as Map<String, dynamic>;
    if (!data.containsKey('success') && !data.containsKey('data')) {
      debugPrint('Warning: Response missing standard structure (success/data fields)');
    }
  }
  
  // Handle Dio errors consistently
  Map<String, dynamic> _handleDioError(DioException e, String method, String path) {
    final errorMessage = _getErrorMessage(e);
    debugPrint('$method Error for $path: $errorMessage');
    
    if (e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      return {
        'success': false,
        'message': errorData['message'] ?? errorMessage,
        'errors': errorData['errors'] ?? {},
        'status': e.response?.statusCode ?? 500
      };
    }
    
    return {
      'success': false,
      'message': errorMessage,
      'status': e.response?.statusCode ?? 500
    };
  }
  
  // Get user-friendly error message
  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return 'Session expired. Please login again.';
        } else if (e.response?.statusCode == 403) {
          return 'You do not have permission to perform this action.';
        } else if (e.response?.statusCode == 404) {
          return 'The requested resource was not found.';
        } else if (e.response?.statusCode == 422) {
          return 'Validation failed. Please check your input.';
        } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed with status: ${e.response?.statusCode}';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }
  
  // Legacy method for backward compatibility
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        debugPrint('JSON decode error: $e');
        throw ApiException('Invalid response format');
      }
    } else {
      throw ApiException('Failed to load data: ${response.statusCode}', statusCode: response.statusCode);
    }
  }
}