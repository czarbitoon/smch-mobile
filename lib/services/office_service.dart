import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'api_service.dart';

final officeServiceProvider = Provider<OfficeService>((ref) {
  return OfficeService(ref.watch(apiServiceProvider));
});

class OfficeService {
  final ApiService _apiService;
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  OfficeService(this._apiService);

  Future<OfficeListResponse> getOffices() async {
    final cacheKey = 'offices';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _apiService.get('offices');
      
      if (response['success'] == true) {
        final offices = response['data'] != null
            ? List<Map<String, dynamic>>.from(response['data'])
            : <Map<String, dynamic>>[];
        
        final result = OfficeListResponse(
          success: true,
          message: response['message'],
          offices: offices,
        );
        
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        return result;
      }
      
      return OfficeListResponse(
        success: false,
        message: response['message'] ?? 'Failed to get offices',
        offices: [],
      );
    } catch (e) {
      debugPrint('Error fetching offices: $e');
      return OfficeListResponse(
        success: false,
        message: e.toString(),
        offices: [],
      );
    }
  }

  Future<OfficeResponse> getOffice(int id) async {
    final cacheKey = 'office_$id';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _apiService.get('offices/$id');
      
      if (response['success'] == true) {
        final office = response['data'] != null
            ? Map<String, dynamic>.from(response['data'])
            : null;
        
        final result = OfficeResponse(
          success: true,
          message: response['message'],
          office: office,
        );
        
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        return result;
      }
      
      return OfficeResponse(
        success: false,
        message: response['message'] ?? 'Failed to get office details',
        office: null,
      );
    } catch (e) {
      debugPrint('Error fetching office: $e');
      return OfficeResponse(
        success: false,
        message: e.toString(),
        office: null,
      );
    }
  }

  Future<OfficeResponse> createOffice(Map<String, dynamic> officeData) async {
    try {
      final response = await _apiService.post('offices', officeData);
      
      _invalidateCache('offices');
      
      if (response['success'] == true) {
        final office = response['data'] != null
            ? Map<String, dynamic>.from(response['data'])
            : null;
        
        return OfficeResponse(
          success: true,
          message: response['message'],
          office: office,
        );
      }
      
      return OfficeResponse(
        success: false,
        message: response['message'] ?? 'Failed to create office',
        office: null,
      );
    } catch (e) {
      debugPrint('Error creating office: $e');
      return OfficeResponse(
        success: false,
        message: e.toString(),
        office: null,
      );
    }
  }

  Future<OfficeResponse> updateOffice(int id, Map<String, dynamic> officeData) async {
    try {
      final response = await _apiService.put('offices/$id', officeData);
      
      _invalidateCache('offices');
      _invalidateCache('office_$id');
      
      if (response['success'] == true) {
        final office = response['data'] != null
            ? Map<String, dynamic>.from(response['data'])
            : null;
        
        return OfficeResponse(
          success: true,
          message: response['message'],
          office: office,
        );
      }
      
      return OfficeResponse(
        success: false,
        message: response['message'] ?? 'Failed to update office',
        office: null,
      );
    } catch (e) {
      debugPrint('Error updating office: $e');
      return OfficeResponse(
        success: false,
        message: e.toString(),
        office: null,
      );
    }
  }

  Future<OfficeResponse> deleteOffice(int id) async {
    try {
      final response = await _apiService.delete('offices/$id');
      
      _invalidateCache('offices');
      _invalidateCache('office_$id');
      
      if (response['success'] == true) {
        return OfficeResponse(
          success: true,
          message: response['message'],
          office: null,
        );
      }
      
      return OfficeResponse(
        success: false,
        message: response['message'] ?? 'Failed to delete office',
        office: null,
      );
    } catch (e) {
      debugPrint('Error deleting office: $e');
      return OfficeResponse(
        success: false,
        message: e.toString(),
        office: null,
      );
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
}

class OfficeListResponse {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>> offices;

  OfficeListResponse({
    required this.success,
    this.message,
    required this.offices,
  });
}

class OfficeResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? office;

  OfficeResponse({
    required this.success,
    this.message,
    this.office,
  });
}