import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  List<Map<String, dynamic>> _deviceReports = [];
  List<Map<String, dynamic>> _officeReports = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<Map<String, dynamic>> get deviceReports => _deviceReports;
  List<Map<String, dynamic>> get devices => _devices;
  List<Map<String, dynamic>> get officeReports => _officeReports;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> loadDeviceReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final devicesResult = await DeviceService().getDevices();
      final reportsResult = await _reportService.getDeviceReports();
      
      if (devicesResult['success'] && reportsResult['success']) {
        // Transform device data similar to DeviceProvider
        final convertField = (value) => value is int ? value : int.tryParse(value.toString()) ?? 0;
        
        _devices = List<Map<String,dynamic>>.from(devicesResult['data']['devices'])
          .map((d) => {
            'id': convertField(d['id']),
            'name': d['name'] ?? 'Unnamed Device',
            'type': d['device_subcategory']?['device_type']?['name'] ?? 'Unknown'
          }).toList();
        
        _deviceReports = List<Map<String, dynamic>>.from(reportsResult['reports']);
        notifyListeners();
      } else {
        _error = reportsResult['message'] ?? 'Failed to load reports';
      }
    } catch (e) {
      _error = 'Failed to load device reports';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOfficeReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _reportService.getOfficeReports();
      if (result['success']) {
        _officeReports = List<Map<String, dynamic>>.from(result['reports']);
      } else {
        _error = reportsResult['message'] ?? 'Failed to load reports';
      }
    } catch (e) {
      _error = 'Failed to load office reports';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _reportService.getNotifications();
      if (result['success']) {
        _notifications = List<Map<String, dynamic>>.from(result['notifications']);
        _updateUnreadCount();
      } else {
        _error = reportsResult['message'] ?? 'Failed to load reports';
      }
    } catch (e) {
      _error = 'Failed to load notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markNotificationAsRead(int id) async {
    try {
      final result = await _reportService.markNotificationAsRead(id);
      if (result['success']) {
        final index = _notifications.indexWhere((notification) => notification['id'] == id);
        if (index != -1) {
          _notifications[index]['read'] = true;
          _updateUnreadCount();
          notifyListeners();
        }
        return true;
      } else {
        _error = reportsResult['message'] ?? 'Failed to load reports';
        return false;
      }
    } catch (e) {
      _error = 'Failed to mark notification as read';
      return false;
    }
  }

  Future<bool> clearAllNotifications() async {
    try {
      final result = await _reportService.clearAllNotifications();
      if (result['success']) {
        _notifications.clear();
        notifyListeners();
        return true;
      } else {
        _error = reportsResult['message'] ?? 'Failed to load reports';
        return false;
      }
    } catch (e) {
      _error = 'Failed to clear notifications';
      return false;
    }
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  set notifications(List<Map<String, dynamic>> value) {
    _notifications = value;
    _updateUnreadCount();
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((notification) => !(notification['read'] ?? false)).length;
    notifyListeners();
  }
}