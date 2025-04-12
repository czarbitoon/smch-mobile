import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'reports_provider.dart';

class DeviceReportProvider extends ReportsProvider {
  List<Map<String, dynamic>> _deviceReports = [];
  bool _isLoading = false;
  String? _error;
  int? _currentDeviceId;

  DeviceReportProvider(ApiService apiService) : super(apiService);

  List<Map<String, dynamic>> get deviceReports => _deviceReports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentDeviceId => _currentDeviceId;

  Future<void> loadDeviceReports(int deviceId) async {
    _isLoading = true;
    _error = null;
    _currentDeviceId = deviceId;
    notifyListeners();

    try {
      final response = await apiService.get('devices/$deviceId/reports');
      if (response['success'] == true) {
        _deviceReports = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to get device reports';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDeviceReport(int deviceId, Map<String, dynamic> reportData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post('devices/$deviceId/reports', reportData);
      if (response['success'] == true) {
        await loadDeviceReports(deviceId);
        return true;
      }
      _error = response['message'] ?? 'Failed to submit device report';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDeviceReport(int deviceId, int reportId, Map<String, dynamic> reportData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.put('devices/$deviceId/reports/$reportId', reportData);
      if (response['success'] == true) {
        await loadDeviceReports(deviceId);
        return true;
      }
      _error = response['message'] ?? 'Failed to update device report';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDeviceReport(int deviceId, int reportId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.delete('devices/$deviceId/reports/$reportId');
      if (response['success'] == true) {
        await loadDeviceReports(deviceId);
        return true;
      }
      _error = response['message'] ?? 'Failed to delete device report';
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

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearDeviceReports() {
    _deviceReports = [];
    _currentDeviceId = null;
    notifyListeners();
  }
}