import 'package:flutter/foundation.dart';
import 'api_service.dart';

class OfficeService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getOffices({int? page}) async {
    debugPrint('[OfficeService] Fetching offices, page: ${page ?? 'all'}');
    try {
      final queryParams = page != null ? {'page': page.toString()} : null;
      debugPrint('[OfficeService] Making API request to endpoint: offices');
      final response = await _apiService.get('offices', queryParams: queryParams);
      debugPrint('[OfficeService] API request completed with status: ${response['success'] == true ? 'success' : 'failure'}');
      debugPrint('[OfficeService] Raw response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');
      
      final result = _processResponse(response);
      debugPrint('[OfficeService] Processed response: success=${result['success']}, offices count: ${result['offices']?.length ?? 0}');
      if (!result['success']) {
        debugPrint('[OfficeService] Error message: ${result['message']}');
      }
      return result;
    } catch (e, stackTrace) {
      debugPrint('[OfficeService] Exception while fetching offices: $e');
      debugPrint('[OfficeService] Exception type: ${e.runtimeType}');
      debugPrint('[OfficeService] Stack trace: $stackTrace');
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
    debugPrint('[OfficeService] Processing API response: ${response.toString().substring(0, response.toString().length > 100 ? 100 : response.toString().length)}...');
    if (response['success'] == true) {
      final data = response['data'];
      debugPrint('[OfficeService] Response data: ${data != null ? 'present' : 'null'}');
      if (data != null) {
        final offices = _extractOffices(data);
        debugPrint('[OfficeService] Extracted offices: ${offices != null ? '${offices.length} offices found' : 'null'}');
        if (offices != null) {
          return {'success': true, 'offices': offices};
        }
      }
      debugPrint('[OfficeService] Invalid response format: data=${data}');
      return {'success': false, 'message': 'Invalid response format'};
    }
    debugPrint('[OfficeService] API returned error: ${response['message'] ?? 'Unknown error'}');
    return {'success': false, 'message': response['message'] ?? 'Unknown error'};
  }

  List<Map<String, dynamic>>? _extractOffices(dynamic data) {
    debugPrint('[OfficeService] Extracting offices from data type: ${data.runtimeType}');
    debugPrint('[OfficeService] Raw data: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');
    
    List? officesList;
    if (data is Map<String, dynamic>) {
      debugPrint('[OfficeService] Data is Map with keys: ${data.keys.join(', ')}');
      
      if (data.containsKey('offices')) {
        final officesData = data['offices'];
        debugPrint('[OfficeService] Found offices key with type: ${officesData.runtimeType}');
        if (officesData is List) {
          officesList = officesData;
          debugPrint('[OfficeService] Found offices key with ${officesList.length} items');
        } else {
          debugPrint('[OfficeService] offices key is not a List: ${officesData.runtimeType}');
        }
      } else if (data.containsKey('data')) {
        final dataValue = data['data'];
        debugPrint('[OfficeService] Found data key with type: ${dataValue.runtimeType}');
        if (dataValue is List) {
          officesList = dataValue;
          debugPrint('[OfficeService] Found data key with ${officesList.length} items');
        } else if (dataValue is Map<String, dynamic> && dataValue.containsKey('offices')) {
          final nestedOffices = dataValue['offices'];
          if (nestedOffices is List) {
            officesList = nestedOffices;
            debugPrint('[OfficeService] Found nested offices in data with ${officesList.length} items');
          }
        } else {
          debugPrint('[OfficeService] data key is not a List or doesn\'t contain offices: ${dataValue.runtimeType}');
        }
      }
    } else if (data is List) {
      officesList = data;
      debugPrint('[OfficeService] Data is List with ${officesList.length} items');
    }

    if (officesList == null) {
      debugPrint('[OfficeService] No offices list found in data');
      return null;
    }

    debugPrint('[OfficeService] Processing ${officesList.length} offices');
    final convertedOffices = <Map<String, dynamic>>[];
    for (var i = 0; i < officesList.length; i++) {
      var office = officesList[i];
      if (office is! Map<String, dynamic>) {
        debugPrint('[OfficeService] Skipping office at index $i: not a Map');
        continue;
      }

      final id = _parseInt(office['id']);
      if (id == 0) {
        debugPrint('[OfficeService] Skipping office with invalid id: ${office['id']}');
        continue;
      }

      final officeName = office['name']?.toString() ?? 'Unnamed Office';
      debugPrint('[OfficeService] Adding office: id=$id, name=$officeName');
      convertedOffices.add({
        'id': id,
        'name': officeName,
        'description': office['description']?.toString() ?? '',
        'devices_count': _parseInt(office['devices_count']),
        'created_at': office['created_at']?.toString(),
        'updated_at': office['updated_at']?.toString(),
      });
    }

    debugPrint('[OfficeService] Extracted ${convertedOffices.length} valid offices');
    return convertedOffices.isNotEmpty ? convertedOffices : null;
  }

  int _parseInt(dynamic value) {
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> _handleError(dynamic e, StackTrace stackTrace, String message) {
    debugPrint('[OfficeService] Error: $e');
    debugPrint('[OfficeService] Error type: ${e.runtimeType}');
    debugPrint('[OfficeService] Error message: $message');
    debugPrint('[OfficeService] StackTrace: $stackTrace');

    String errorMessage = message;
    if (e is Exception) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out: Please try again';
      } else if (e.toString().contains('Invalid response format')) {
        errorMessage = 'Server returned invalid data format';
      }
    }

    return {
      'success': false,
      'message': errorMessage,
      'error_type': e.runtimeType.toString(),
      'error_details': e.toString()
    };
  }
}