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
  return ApiService(baseUrl: AppConfig.apiUrl);
});

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
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

  ApiService({
    required this.baseUrl,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        debugPrint('API Error: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } catch (e) {
      debugPrint('PUT Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(String path, dynamic data) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } catch (e) {
      debugPrint('PATCH Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFile(String path, String filePath, String fieldName) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(path, data: formData);
      return response.data;
    } catch (e) {
      debugPrint('Upload Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadWithImage(String path, Map<String, dynamic> data, String imagePath) async {
    try {
      final formData = FormData.fromMap({
        ...data,
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(path, data: formData);
      return response.data;
    } catch (e) {
      debugPrint('Upload Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}