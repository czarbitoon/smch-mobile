import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsProvider extends ChangeNotifier {
  @protected
  final ApiService _apiService;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentReport;

  static const List<String> priorityLevels = ['Low', 'Medium', 'High', 'Critical'];
  static const List<String> statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

  ReportsProvider(this._apiService);
  
  // Protected getter for _apiService to be used by child classes
  @protected
  ApiService get apiService => _apiService;

  Map<String, dynamic>? get currentReport => _currentReport;
  List<Map<String, dynamic>> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('reports');
      if (response['success'] == true) {
        _reports = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to get reports';
      }
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

      final response = await _apiService.get('reports/$reportId');
      
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

  Future<bool> resolveReport(int reportId, String resolutionNotes, {required bool isAdminOrStaff}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!isAdminOrStaff) {
        _error = 'You do not have permission to resolve reports';
        return false;
      }
      
      final response = await _apiService.post('reports/$reportId/resolve', {
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

  Future<bool> submitReport(Map<String, dynamic> reportData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('reports', reportData);
      if (response['success'] == true) {
        await loadReports();
        return true;
      }
      _error = response['message'] ?? 'Failed to submit report';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateReport(int reportId, Map<String, dynamic> reportData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('reports/$reportId', reportData);
      if (response['success'] == true) {
        await loadReports();
        return true;
      }
      _error = response['message'] ?? 'Failed to update report';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReport(int reportId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('reports/$reportId');
      if (response['success'] == true) {
        await loadReports();
        return true;
      }
      _error = response['message'] ?? 'Failed to delete report';
      return false;
    } catch (e) {
      _error = e.toString();
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

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}