import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DeviceReportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentReport;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get currentReport => _currentReport;

  static const List<String> priorityLevels = ['Low', 'Medium', 'High', 'Critical'];
  static const List<String> statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

  Future<bool> submitReport({
    required int deviceId,
    required String description,
    String priority = 'Medium',
    String status = 'Pending',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/reports', {
        'device_id': deviceId,
        'description': description,
        'priority': priority,
        'status': status,
      });

      _currentReport = response['data'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Map<String, dynamic>) {
        _error = e['message'] ?? e.toString();
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveReport(int reportId, String resolutionNotes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/reports/$reportId/resolve', {
        'resolution_notes': resolutionNotes,
      });

      _currentReport = response['data'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is Map<String, dynamic>) {
        _error = e['message'] ?? e.toString();
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentReport() {
    _currentReport = null;
    notifyListeners();
  }
}