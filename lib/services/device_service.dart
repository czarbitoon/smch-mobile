import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DeviceService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDevices({int? page, Map<String, dynamic>? filters}) async {
    try {
      final queryParams = <String, String>{};

      if (page != null) queryParams['page'] = page.toString();
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            queryParams[key] = value.toString();
          }
        });
      }

      final response = await _apiService.get('devices', queryParams: queryParams);
      return _processResponse(response, 'devices');
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch devices');
    }
  }

  Future<Map<String, dynamic>> createDevice(Map<String, dynamic> deviceData) async {
    return _handleApiCall(() => _apiService.post('devices', deviceData), 'create');
  }

  Future<Map<String, dynamic>> updateDevice(int id, Map<String, dynamic> deviceData) async {
    return _handleApiCall(() => _apiService.put('devices/$id', deviceData), 'update');
  }

  Future<Map<String, dynamic>> deleteDevice(int id) async {
    return _handleApiCall(() => _apiService.delete('devices/$id'), 'delete');
  }

  Future<Map<String, dynamic>> getOffices() async {
    return _handleApiCall(() => _apiService.get('offices'), 'fetch offices');
  }

  Future<Map<String, dynamic>> getDeviceTypes() async {
    return _handleApiCall(() => _apiService.get('device-types'), 'fetch device types');
  }

  Future<Map<String, dynamic>> _handleApiCall(Future<Map<String, dynamic>> Function() apiCall, String action) async {
    try {
      final response = await apiCall();
      return _processResponse(response, action);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to $action');
    }
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

  Map<String, dynamic> _handleError(dynamic e, StackTrace stackTrace, String message) {
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    return {'success': false, 'message': message};
  }
}
