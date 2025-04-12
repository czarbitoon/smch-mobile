import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';

/// Provider for the DeviceService
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.watch(apiServiceProvider));
});

/// Service class for handling device-related API operations
class DeviceService {
  final ApiService _apiService;
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  DeviceService(this._apiService);

  /// Fetches a list of devices with optional pagination and filtering
  Future<DeviceListResponse> getDevices({int? page, Map<String, dynamic>? filters}) async {
    try {
      final response = await _apiService.get('devices', queryParameters: {
        if (page != null) 'page': page.toString(),
        ...?filters,
      });
      return DeviceListResponse.fromJson(response);
    } catch (e) {
      return DeviceListResponse(
        success: false,
        message: e.toString(),
        data: null,
        pagination: null,
      );
    }
  }

  /// Fetches details of a specific device
  Future<DeviceResponse> getDevice(int id) async {
    try {
      final response = await _apiService.get('devices/$id');
      return DeviceResponse.fromJson(response);
    } catch (e) {
      return DeviceResponse(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  /// Creates a new device
  Future<DeviceResponse> createDevice(DeviceModel device) async {
    try {
      final response = await _apiService.post('devices', device.toJson());
      return DeviceResponse.fromJson(response);
    } catch (e) {
      return DeviceResponse(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  /// Updates an existing device
  Future<DeviceResponse> updateDevice(int id, DeviceModel device) async {
    try {
      final response = await _apiService.put('devices/$id', device.toJson());
      return DeviceResponse.fromJson(response);
    } catch (e) {
      return DeviceResponse(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  /// Deletes a device
  Future<DeviceResponse> deleteDevice(int id) async {
    try {
      final response = await _apiService.delete('devices/$id');
      return DeviceResponse.fromJson(response);
    } catch (e) {
      return DeviceResponse(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  /// Fetches available offices
  Future<OfficeListResponse> getOffices() async {
    final cacheKey = 'offices';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _apiService.get('offices');
      final result = _processResponse(response, 'offices');
      if (result['success'] == true) {
        final offices = (result['data']['offices'] as List).cast<Map<String, dynamic>>();
        final response = OfficeListResponse(offices: offices);
        
        _cache[cacheKey] = response;
        _cacheTimestamps[cacheKey] = DateTime.now();
        return response;
      }
      throw Exception(result['message']);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch offices');
    }
  }

  /// Fetches device categories
  Future<CategoryListResponse> getDeviceCategories() async {
    final cacheKey = 'categories';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _apiService.get('device-categories');
      final result = _processResponse(response, 'categories');
      if (result['success'] == true) {
        final categories = (result['data']['categories'] as List).cast<Map<String, dynamic>>();
        final response = CategoryListResponse(categories: categories);
        
        _cache[cacheKey] = response;
        _cacheTimestamps[cacheKey] = DateTime.now();
        return response;
      }
      throw Exception(result['message']);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch device categories');
    }
  }

  /// Fetches device types for a specific category
  Future<TypeListResponse> getDeviceTypes(int categoryId) async {
    final cacheKey = 'types_$categoryId';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _apiService.get('device-types', queryParameters: {
        'category_id': categoryId.toString(),
      });
      final result = _processResponse(response, 'types');
      if (result['success'] == true) {
        final types = (result['data']['types'] as List).cast<Map<String, dynamic>>();
        final response = TypeListResponse(types: types);
        
        _cache[cacheKey] = response;
        _cacheTimestamps[cacheKey] = DateTime.now();
        return response;
      }
      throw Exception(result['message']);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch device types');
    }
  }

  /// Uploads an image for a device
  Future<ImageResponse> uploadDeviceImage(int deviceId, String imagePath) async {
    try {
      final response = await _apiService.uploadWithImage(
        'devices/$deviceId/image',
        {},
        imagePath,
      );
      return ImageResponse.fromJson(response);
    } catch (e) {
      return ImageResponse(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  /// Fetches the image URL for a device
  Future<ImageResponse> getDeviceImage(int deviceId) async {
    try {
      final response = await _apiService.get('devices/$deviceId/image');
      return ImageResponse.fromJson(response);
    } catch (e) {
      return ImageResponse(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  /// Fetches reports for a specific device
  Future<Map<String, dynamic>> getDeviceReports(int deviceId) async {
    try {
      final response = await _apiService.get('devices/$deviceId/reports');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  /// Submits a report for a specific device
  Future<Map<String, dynamic>> submitDeviceReport(int deviceId, Map<String, dynamic> reportData) async {
    try {
      final response = await _apiService.post('devices/$deviceId/reports', reportData);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  /// Updates a report for a specific device
  Future<Map<String, dynamic>> updateDeviceReport(int deviceId, int reportId, Map<String, dynamic> reportData) async {
    try {
      final response = await _apiService.put('devices/$deviceId/reports/$reportId', reportData);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  /// Deletes a report for a specific device
  Future<Map<String, dynamic>> deleteDeviceReport(int deviceId, int reportId) async {
    try {
      final response = await _apiService.delete('devices/$deviceId/reports/$reportId');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _invalidateCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  Map<String, dynamic> _processResponse(Map<String, dynamic> response, String key) {
    if (response['success'] == true) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data[key] is List) {
        for (var item in (data[key] as List)) {
          _convertNumericFields(item);
        }
      }
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': response['message']?.toString() ?? 'Unknown error'};
  }

  void _convertNumericFields(Map<String, dynamic> item) {
    if (item.containsKey('id')) item['id'] = _parseInt(item['id']);
    if (item.containsKey('office_id')) item['office_id'] = _parseInt(item['office_id']);
    if (item['type'] is Map<String, dynamic>) {
      item['type']['id'] = _parseInt(item['type']['id']);
    }
    if (item['device_subcategory'] is Map<String, dynamic> &&
        item['device_subcategory']['device_type'] is Map<String, dynamic>) {
      item['device_subcategory']['device_type']['id'] = _parseInt(item['device_subcategory']['device_type']['id']);
    }
  }

  int _parseInt(dynamic value) {
    return int.tryParse(value.toString()) ?? 0;
  }

  T _handleError<T>(dynamic e, StackTrace stackTrace, String message) {
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    throw Exception(message);
  }
}

/// Response classes for type safety
class DeviceListResponse {
  final bool success;
  final String? message;
  final List<DeviceModel>? data;
  final Map<String, dynamic>? pagination;
  final Meta? meta;

  DeviceListResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
    this.meta,
  });

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceListResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => DeviceModel.fromJson(e))
              .toList()
          : null,
      pagination: json['pagination'],
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

class DeviceResponse {
  final bool success;
  final String? message;
  final DeviceModel? data;

  DeviceResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? DeviceModel.fromJson(json['data']) : null,
    );
  }
}

class OfficeListResponse {
  final List<Map<String, dynamic>> offices;

  OfficeListResponse({required this.offices});
}

class CategoryListResponse {
  final List<Map<String, dynamic>> categories;

  CategoryListResponse({required this.categories});
}

class TypeListResponse {
  final List<Map<String, dynamic>> types;

  TypeListResponse({required this.types});
}

class ImageResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  ImageResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ImageResponse.fromJson(Map<String, dynamic> json) {
    return ImageResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}

class Meta {
  final int lastPage;
  final int total;
  final int currentPage;
  final int perPage;

  Meta({
    required this.lastPage,
    required this.total,
    required this.currentPage,
    required this.perPage,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
    );
  }
}
