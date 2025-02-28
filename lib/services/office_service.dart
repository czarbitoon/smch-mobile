import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OfficeService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getOffices() async {
    try {
      final token = await _authService.getToken();
      print('[OfficeService] Fetching offices with token: ${token != null ? 'exists' : 'not found'}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/offices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[OfficeService] Get offices response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Enhanced null-check and type validation
        if (data == null || !data.containsKey('data')) {
          print('[OfficeService] Invalid response format: missing data object');
          return {'success': false, 'message': 'Invalid server response format', 'error_type': 'data_format'};
        }

        if (!data['data'].containsKey('offices') || data['data']['offices'] == null) {
          print('[OfficeService] Invalid response format: missing offices array');
          return {'success': false, 'message': 'Invalid office data format', 'error_type': 'offices_format'};
        }

        final offices = data['data']['offices'];
        if (offices is! List) {
          print('[OfficeService] Invalid response format: offices is not an array');
          return {'success': false, 'message': 'Invalid office data type', 'error_type': 'offices_type'};
        }
        
        final List<Map<String, dynamic>> convertedOffices = [];
        
        for (var office in offices) {
          if (office is! Map<String, dynamic>) {
            print('[OfficeService] Invalid office format: $office');
            continue;
          }

          final id = _safeIntConvert(office['id']);
          if (id == 0) {
            print('[OfficeService] Invalid office ID: ${office['id']}');
            continue;
          }
          
          convertedOffices.add({
            'id': id,
            'name': office['name']?.toString() ?? 'Unnamed Office',
            'description': office['description']?.toString() ?? '',
            'devices_count': _safeIntConvert(office['devices_count']),
            'created_at': office['created_at']?.toString(),
            'updated_at': office['updated_at']?.toString(),
          });
        }

        if (convertedOffices.isEmpty && offices.isNotEmpty) {
          print('[OfficeService] All offices were invalid');
          return {'success': false, 'message': 'Invalid office data received', 'error_type': 'data_validation'};
        }

        print('[OfficeService] Successfully fetched ${convertedOffices.length} offices');
        return {'success': true, 'offices': convertedOffices};
      } else {
        final error = json.decode(response.body);
        print('[OfficeService] Failed to fetch offices: ${error['message']}');
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print('[OfficeService] Critical error: ${e.toString()}');
      return {'success': false, 'message': 'Data processing failed'};
    }
  }

  Future<Map<String, dynamic>> createOffice(Map<String, dynamic> officeData) async {
    try {
      final token = await _authService.getToken();
      
      // Add mobile-compatible validation
      final validatedData = {
        'name': officeData['name']?.toString() ?? '',
        'description': officeData['description']?.toString() ?? '',
        'devices_count': _safeIntConvert(officeData['devices_count']),
      };
      
      print('[OfficeService] Creating office with data: $validatedData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/offices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(validatedData),
      );

      print('[OfficeService] Create office response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('[OfficeService] Successfully created office: ${data['office']}');
        return {'success': true, 'office': data['office']};
      } else {
        final error = json.decode(response.body);
        print('[OfficeService] Failed to create office: ${error['message']}');
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print('[OfficeService] Connection error while creating office: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateOffice(int id, Map<String, dynamic> officeData) async {
    try {
      final token = await _authService.getToken();
      
      // Add mobile-compatible validation
      final validatedData = {
        'name': officeData['name']?.toString() ?? '',
        'description': officeData['description']?.toString() ?? '',
        'devices_count': _safeIntConvert(officeData['devices_count']),
      };
      
      print('[OfficeService] Updating office $id with data: $validatedData');
      
      final response = await http.put(
        Uri.parse('$baseUrl/offices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(validatedData),
      );

      print('[OfficeService] Update office response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[OfficeService] Successfully updated office: ${data['office']}');
        return {'success': true, 'office': data['office']};
      } else {
        final error = json.decode(response.body);
        print('[OfficeService] Failed to update office: ${error['message']}');
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print('[OfficeService] Connection error while updating office: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  int _safeIntConvert(dynamic value) {
    if (value == null) {
      print('[OfficeService] Null value provided for integer conversion');
      return 0;
    }
    if (value is int) return value;
    if (value is String) {
      print('[OfficeService] Converting string value "$value" to integer');
      // Remove any non-numeric characters except minus sign
      final cleanedValue = value.replaceAll(RegExp(r'[^0-9-]'), '');
      if (cleanedValue.isEmpty) {
        print('[OfficeService] String value "$value" contains no valid numeric characters');
        return 0;
      }
      final result = int.tryParse(cleanedValue);
      if (result == null) {
        print('[OfficeService] Failed to convert string "$value" to integer');
        return 0;
      }
      print('[OfficeService] Successfully converted "$value" to $result');
      return result;
    }
    if (value is double) {
      final result = value.toInt();
      print('[OfficeService] Converted double $value to integer $result');
      return result;
    }
    print('[OfficeService] Unsupported type for integer conversion: ${value.runtimeType}, value: $value');
    return 0;
  }

  Future<Map<String, dynamic>> deleteOffice(int id) async {
    try {
      final token = await _authService.getToken();
      
      print('[OfficeService] Deleting office with ID: $id');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/offices/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('[OfficeService] Delete office response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[OfficeService] Successfully deleted office');
        return {'success': true, 'message': data['message']};
      } else {
        final error = json.decode(response.body);
        print('[OfficeService] Failed to delete office: ${error['message']}');
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print('[OfficeService] Connection error while deleting office: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }
}