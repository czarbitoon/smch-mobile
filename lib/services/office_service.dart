import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OfficeService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getOffices() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/offices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'offices': data['offices']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> createOffice(Map<String, dynamic> officeData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/offices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(officeData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'office': data['office']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateOffice(int id, Map<String, dynamic> officeData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/offices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(officeData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'office': data['office']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> deleteOffice(int id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/offices/$id'),
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