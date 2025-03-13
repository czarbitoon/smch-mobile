import 'package:flutter/foundation.dart';
import 'api_service.dart';

class OfficeService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getOffices({int? page}) async {
    try {
      final queryParams = page != null ? {'page': page.toString()} : null;
      final response = await _apiService.get('offices', queryParams: queryParams);
      return _processResponse(response);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch offices');
    }
  }

  Future<Map<String, dynamic>> createOffice(Map<String, dynamic> officeData) async {
    return _handleApiCall(() => _apiService.post('offices', officeData), 'create office');
  }

  Future<Map<String, dynamic>> updateOffice(int id, Map<String, dynamic> officeData) async {
    return _handleApiCall(() => _apiService.put('offices/$id', officeData), 'update office');
  }

  Future<Map<String, dynamic>> deleteOffice(int id) async {
    return _handleApiCall(() => _apiService.delete('offices/$id'), 'delete office');
  }

  Future<Map<String, dynamic>> _handleApiCall(Future<Map<String, dynamic>> Function() apiCall, String action) async {
    try {
      final response = await apiCall();
      return _processResponse(response);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to $action');
    }
  }

  Map<String, dynamic> _processResponse(Map<String, dynamic> response) {
    if (response['success'] == true) {
      final data = response['data'];
      if (data != null) {
        final offices = _extractOffices(data);
        if (offices != null) {
          return {'success': true, 'offices': offices};
        }
      }
      return {'success': false, 'message': 'Invalid response format'};
    }
    return {'success': false, 'message': response['message'] ?? 'Unknown error'};
  }

  List<Map<String, dynamic>>? _extractOffices(dynamic data) {
    List? officesList;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('offices')) {
        officesList = data['offices'] as List?;
      } else if (data.containsKey('data')) {
        officesList = data['data'] as List?;
      }
    } else if (data is List) {
      officesList = data;
    }

    if (officesList == null) return null;

    final convertedOffices = <Map<String, dynamic>>[];
    for (var office in officesList) {
      if (office is! Map<String, dynamic>) continue;

      final id = _parseInt(office['id']);
      if (id == 0) continue;

      convertedOffices.add({
        'id': id,
        'name': office['name']?.toString() ?? 'Unnamed Office',
        'description': office['description']?.toString() ?? '',
        'devices_count': _parseInt(office['devices_count']),
        'created_at': office['created_at']?.toString(),
        'updated_at': office['updated_at']?.toString(),
      });
    }

    return convertedOffices.isNotEmpty ? convertedOffices : null;
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