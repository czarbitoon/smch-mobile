import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DeviceReportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> submitReport(int deviceId, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/device-reports', {
        'device_id': deviceId,
        'description': description,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}