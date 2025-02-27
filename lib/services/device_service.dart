import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DeviceService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDevices({int? page}) async {
    try {
      final response = await _apiService.get('devices${page != null ? "?page=$page" : ""}');
      debugPrint('Raw API response: ${json.encode(response)}');
      
      if (response['success']) {
        final dynamic data = response['data'];
        debugPrint('Processed devices data: ${json.encode(data)}');
        return {'success': true, 'data': data};
      } else {
        final String errorMessage = response['message']?.toString() ?? 'Unknown error occurred';
        debugPrint('Failed to fetch devices: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      debugPrint('Error in getDevices: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Failed to fetch devices: $e'};
    }
  }

  Future<Map<String, dynamic>> createDevice(Map<String, dynamic> deviceData) async {
    try {
      debugPrint('Creating device with data: ${json.encode(deviceData)}');
      final response = await _apiService.post('devices', deviceData);
      debugPrint('Create device response: ${json.encode(response)}');
      
      if (response['success']) {
        final device = response['data'];
        if (device == null) {
          debugPrint('Warning: Created device data is null');
          return {'success': false, 'message': 'Device created but no data returned'};
        }
        debugPrint('Successfully created device: ${json.encode(device)}');
        return {'success': true, 'device': device};
      } else {
        final String errorMessage = response['message']?.toString() ?? 'Failed to create device';
        debugPrint('Failed to create device: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      debugPrint('Error in createDevice: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Failed to create device: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDevice(int id, Map<String, dynamic> deviceData) async {
    try {
      debugPrint('Updating device $id with data: ${json.encode(deviceData)}');
      final response = await _apiService.post('devices/$id', deviceData);
      debugPrint('Update device response: ${json.encode(response)}');
      
      if (response['success']) {
        final device = response['data'];
        if (device == null) {
          debugPrint('Warning: Updated device data is null');
          return {'success': false, 'message': 'Device updated but no data returned'};
        }
        debugPrint('Successfully updated device: ${json.encode(device)}');
        return {'success': true, 'device': device};
      } else {
        final String errorMessage = response['message']?.toString() ?? 'Failed to update device';
        debugPrint('Failed to update device: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      debugPrint('Error in updateDevice: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Failed to update device: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteDevice(int id) async {
    try {
      debugPrint('Deleting device $id');
      final response = await _apiService.post('devices/$id/delete', {});
      debugPrint('Delete device response: ${json.encode(response)}');
      
      if (response['success']) {
        debugPrint('Successfully deleted device $id');
        return {'success': true, 'message': 'Device deleted successfully'};
      } else {
        final String errorMessage = response['message']?.toString() ?? 'Failed to delete device';
        debugPrint('Failed to delete device: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      debugPrint('Error in deleteDevice: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Failed to delete device: $e'};
    }
  }
}