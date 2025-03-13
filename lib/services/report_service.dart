import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getReports({int? page, Map<String, dynamic>? filters}) async {
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

      final response = await _apiService.get('reports', queryParams: queryParams);
      return _processResponse(response);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch reports');
    }
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    return _handleApiCall(() => _apiService.post('reports', reportData), 'create report');
  }

  Future<Map<String, dynamic>> updateReport(int id, Map<String, dynamic> reportData) async {
    return _handleApiCall(() => _apiService.put('reports/$id', reportData), 'update report');
  }

  Future<Map<String, dynamic>> deleteReport(int id) async {
    return _handleApiCall(() => _apiService.delete('reports/$id'), 'delete report');
  }

  Future<Map<String, dynamic>> getNotifications({int? page}) async {
    try {
      final queryParams = page != null ? {'page': page.toString()} : null;
      final response = await _apiService.get('notifications', queryParams: queryParams);
      return _processResponse(response);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to fetch notifications');
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    return _handleApiCall(
      () => _apiService.post('notifications/$id/read', {}),
      'mark notification as read'
    );
  }

  Future<Map<String, dynamic>> clearAllNotifications() async {
    return _handleApiCall(
      () => _apiService.post('notifications/clear', {}),
      'clear all notifications'
    );
  }

  Future<Map<String, dynamic>> _handleApiCall(
    Future<Map<String, dynamic>> Function() apiCall,
    String action
  ) async {
    try {
      final response = await apiCall();
      return _processResponse(response);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, 'Failed to $action');
    }
  }

  Map<String, dynamic> _processResponse(Map<String, dynamic> response) {
    return response;
  }

  Map<String, dynamic> _handleError(dynamic error, StackTrace stackTrace, String message) {
    String errorMessage = message;
    Map<String, dynamic> errorDetails = {};

    if (error is Map<String, dynamic>) {
      if (error['status'] == 422) {
        errorMessage = 'Validation failed';
        errorDetails = error['errors'] ?? {};
        debugPrint('Validation Error: ${error['message']}\nDetails: $errorDetails');
      }
    }

    debugPrint('$errorMessage: $error\n$stackTrace');
    return {
      'success': false,
      'message': errorMessage,
      'error': error.toString(),
      'details': errorDetails
    };
  }
}