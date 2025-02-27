import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReportService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getDeviceReports() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reports/devices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'reports': data['reports']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getOfficeReports() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reports/offices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'reports': data['reports']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'notifications': data['notifications']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
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

  Future<Map<String, dynamic>> clearAllNotifications() async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/clear'),
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