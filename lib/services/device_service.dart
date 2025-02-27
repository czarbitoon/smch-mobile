import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DeviceService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getDevices() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'devices': data['devices']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> createDevice(Map<String, dynamic> deviceData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/devices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(deviceData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'device': data['device']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateDevice(int id, Map<String, dynamic> deviceData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/devices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(deviceData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'device': data['device']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> deleteDevice(int id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/devices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }
}