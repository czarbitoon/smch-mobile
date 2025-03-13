import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _deviceReports = [];
  bool _isLoading = false;
  String? _error;

  static const List<String> priorityLevels = ['Low', 'Medium', 'High', 'Critical'];
  static const List<String> statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

  ReportsProvider(this._apiService);

  List<Map<String, dynamic>> get reports => _reports;
  List<Map<String, dynamic>> get deviceReports => _deviceReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports() async {
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
      final response = await _apiService.get('/reports/$reportId');
      if (response is Map<String, dynamic>) {
        if (response['report'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['report']);
        }
        return response;
      } else if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
      throw Exception('Report details not found');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> submitDeviceReport(int deviceId, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/reports', {
        'device_id': deviceId,
        'description': description,
      });
      await loadReports();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReport({required String description, required String priority, required String status, int? deviceId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> reportData = {
        'description': description,
        'priority': priority,
        'status': status,
      };
      
      if (deviceId != null) {
        reportData['device_id'] = deviceId;
      }
      
      await _apiService.post('/reports', reportData);
      await loadReports();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  }