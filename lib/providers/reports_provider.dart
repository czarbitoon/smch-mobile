import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _deviceReports = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentReport;

  static const List<String> priorityLevels = ['Low', 'Medium', 'High', 'Critical'];
  static const List<String> statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

  ReportsProvider(this._apiService);

  Map<String, dynamic>? get currentReport => _currentReport;

  List<Map<String, dynamic>> get reports => _reports;
  List<Map<String, dynamic>> get deviceReports => _deviceReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cache timeout duration
  static const _cacheTimeout = Duration(minutes: 5);
  DateTime? _lastFetchTime;

  Future<void> loadReports() async {
    // Return cached data if within timeout
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheTimeout &&
        _reports.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/reports');
      if (response is Map<String, dynamic> && response['reports'] is List) {
        _reports = List<Map<String, dynamic>>.from(
          (response['reports'] as List).map((item) => 
            item is Map<String, dynamic> ? item : <String, dynamic>{}
          )
        );
      } else if (response is List) {
        _reports = List<Map<String, dynamic>>.from(
          (response as List).map((item) => 
            item is Map<String, dynamic> ? item : <String, dynamic>{}
          )
        );
      } else {
        _reports = [];
      }
      _lastFetchTime = DateTime.now();

      _deviceReports = _reports.where((report) => report['device_id'] != null).toList();
    } catch (e) {
      _error = e.toString();
      _reports = [];
      _deviceReports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/reports/generate', {});
      await loadReports();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getReportDetails(int reportId) async {
    try {
      if (reportId <= 0) {
        throw Exception('Invalid report ID');
      }

      final response = await _apiService.get('/reports/$reportId');
      
      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to fetch report details');
      }

      if (response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      } else if (response['report'] != null) {
        return Map<String, dynamic>.from(response['report']);
      }
      
      throw Exception('Report details not found');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
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

      if (response['success'] == true) {
        _currentReport = response['data'];
        await loadReports();
        return true;
      }

      _error = response['message']?.toString() ?? 'Failed to resolve report';
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> submitDeviceReport(int deviceId, String description, {String priority = 'Medium', String status = 'Pending'}) async {
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
      await loadReports();
      return true;
    } catch (e) {
      if (e is Map<String, dynamic>) {
        _error = e['message'] ?? e.toString();
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReport({
    required int deviceId,
    required String title,
    required String description,
    required String priority,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate input data before submission
      if (title.trim().isEmpty) {
        _error = 'Title is required';
        return false;
      }

      if (description.trim().isEmpty) {
        _error = 'Description is required';
        return false;
      }

      if (!priorityLevels.contains(priority)) {
        _error = 'Invalid priority level';
        return false;
      }

      if (!statusOptions.contains(status)) {
        _error = 'Invalid status';
        return false;
      }

      final Map<String, dynamic> reportData = {
        'device_id': deviceId,
        'title': title.trim(),
        'description': description.trim(),
        'priority': priority,
        'status': status,
      };
      
      print('Submitting report with validated data: $reportData');
      
      final response = await _apiService.post('/reports', reportData);
      print('API Response: $response');
      
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          await loadReports();
          if (response['data'] != null) {
            final reportData = Map<String, dynamic>.from(response['data']);
            _reports = [..._reports, reportData];
            _deviceReports = _reports.where((report) => report['device_id'] != null).toList();
          }
          notifyListeners();
          return true;
        } else {
          _error = response['message']?.toString() ?? 'Unknown error';
          if (response['status'] == 422) {
            final errors = response['errors'] is Map
                ? Map<String, dynamic>.from(response['errors'])
                : <String, dynamic>{};
            if (errors.isEmpty) {
              _error = 'Validation failed. Please check your input and try again.';
            } else {
              final errorMessages = errors.entries
                  .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
                  .join('\n');
              _error = 'Validation failed:\n$errorMessages';
            }
            print('Validation errors: $errors');
          } else {
            print('Error submitting report: ${response['message']}');
          }
        }
      } else {
        _error = 'Invalid response format from server';
      }
      return false;
    } catch (e) {
      print('Exception while submitting report: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}