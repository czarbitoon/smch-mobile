import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _error;

  ReportsProvider(this._apiService);

  List<Map<String, dynamic>> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/reports');
      _reports = List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      _error = e.toString();
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getReportDetails(int reportId) async {
    try {
      final response = await _apiService.get('/reports/$reportId');
      return response['data'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}