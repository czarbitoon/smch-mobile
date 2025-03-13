import 'package:flutter/material.dart';
import '../services/report_service.dart';
import 'base_provider.dart';

class ReportProvider extends BaseProvider {
  final ReportService _reportService = ReportService();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _notifications = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  Map<String, dynamic> _filters = {};

  List<Map<String, dynamic>> get reports => _reports;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get hasMoreData => _hasMoreData;
  Map<String, dynamic> get filters => _filters;

  Future<void> loadReports({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _reports = [];
      _hasMoreData = true;
    }

    if (!_hasMoreData) return;

    return handleAsync(() async {
      final result = await _reportService.getReports(
        page: _currentPage,
        filters: _filters,
      );

      if (result['success']) {
        final newReports = List<Map<String, dynamic>>.from(result['reports'] ?? []);
        if (newReports.isEmpty) {
          _hasMoreData = false;
        } else {
          _reports.addAll(newReports);
          _currentPage++;
        }
      } else {
        setError(result['message']);
      }
    }, errorMessage: 'Failed to load reports');
  }

  Future<void> createReport(Map<String, dynamic> reportData) async {
    return handleAsync(() async {
      final result = await _reportService.createReport(reportData);
      if (result['success']) {
        await loadReports(refresh: true);
      } else {
        final errorMessage = result['message'];
        final errorDetails = result['details'] as Map<String, dynamic>?;
        
        if (errorDetails != null && errorDetails.isNotEmpty) {
          setError('$errorMessage: ${errorDetails.values.join(', ')}');
        } else {
          setError(result['message']);
        }
      }
    }, errorMessage: 'Failed to create report');
  }

  Future<void> updateReport(int id, Map<String, dynamic> reportData) async {
    return handleAsync(() async {
      final result = await _reportService.updateReport(id, reportData);
      if (result['success']) {
        final index = _reports.indexWhere((report) => report['id'] == id);
        if (index != -1) {
          _reports[index] = {..._reports[index], ...reportData};
          notifyListeners();
        }
      } else {
        setError(result['message']);
      }
    }, errorMessage: 'Failed to update report');
  }

  Future<void> deleteReport(int id) async {
    return handleAsync(() async {
      final result = await _reportService.deleteReport(id);
      if (result['success']) {
        _reports.removeWhere((report) => report['id'] == id);
        notifyListeners();
      } else {
        setError(result['message']);
      }
    }, errorMessage: 'Failed to delete report');
  }

  void updateFilters(Map<String, dynamic> newFilters) {
    _filters = newFilters;
    loadReports(refresh: true);
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _notifications = [];
    }

    return handleAsync(() async {
      final result = await _reportService.getNotifications();
      if (result['success']) {
        _notifications = List<Map<String, dynamic>>.from(result['data'] ?? []);
      } else {
        setError(result['message']);
      }
    }, errorMessage: 'Failed to load notifications');
  }

  Future<void> markNotificationAsRead(int id) async {
    return handleAsync(() async {
      final result = await _reportService.markNotificationAsRead(id);
      if (result['success']) {
        final index = _notifications.indexWhere((notification) => notification['id'] == id);
        if (index != -1) {
          _notifications[index] = {..._notifications[index], 'read': true};
          notifyListeners();
        }
      } else {
        setError(result['message']);
      }
    }, errorMessage: 'Failed to mark notification as read');
  }

  Future<void> clearAllNotifications() async {
    return handleAsync(() async {
      final result = await _reportService.clearAllNotifications();
      if (result['success']) {
        _notifications = [];
        notifyListeners();
      } else {
        setError(result['message']);
      }
    }, errorMessage: 'Failed to clear notifications');
  }
}