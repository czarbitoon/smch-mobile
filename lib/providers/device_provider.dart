import 'package:flutter/material.dart';
import '../services/device_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 10;
  int _total = 0;

  List<Map<String, dynamic>> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;

  Future<void> loadDevices({int? page}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Starting to load devices... Page: ${page ?? _currentPage}');
      final result = await _deviceService.getDevices(page: page ?? _currentPage);
      if (result['success'] == true && result['data'] != null) {
        debugPrint('Successfully received devices data');
        final data = result['data'] as Map<String, dynamic>;
        final devicesData = data['devices'] as List? ?? [];
        _devices = devicesData.map((device) {
          final deviceMap = Map<String, dynamic>.from(device);
          
          // Unified type conversion
          final convertField = (dynamic value) => value is int 
              ? value 
              : int.tryParse(value.toString()) ?? 0;

          deviceMap['id'] = convertField(deviceMap['id']);
          deviceMap['office_id'] = deviceMap['office_id'] != null 
              ? convertField(deviceMap['office_id']) 
              : null;

          return deviceMap;
        }).where((d) => d['id'] != 0).toList(); // Filter invalid entries
        
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        _currentPage = int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1;
        _lastPage = int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1;
        _total = int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
        _perPage = int.tryParse(pagination['per_page']?.toString() ?? '10') ?? 10;
        debugPrint('Number of devices loaded: ${_devices.length}');
      } else {
        debugPrint('Failed to load devices: ${result['message']}');
        _error = result['message'];
      }
    } catch (e) {
      debugPrint('Exception while loading devices: $e');
      _error = 'Failed to load devices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('Device loading process completed. Error: $_error');
    }
  }

  Future<void> nextPage() async {
    if (_currentPage < _lastPage) {
      await loadDevices(page: _currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await loadDevices(page: _currentPage - 1);
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _lastPage && page != _currentPage) {
      await loadDevices(page: page);
    }
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _isLoading = true;
    _currentPage = 1;
    notifyListeners();

    try {
      debugPrint('Applying filters: $filters');
      if (filters.containsKey('office_id') && filters['office_id'] == null) {
        filters.remove('office_id');
      }
      final result = await _deviceService.getDevices(page: _currentPage, filters: filters);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final devicesData = data['devices'] as List? ?? [];
        _devices = devicesData.map((device) {
          final deviceMap = Map<String, dynamic>.from(device);
          
          // Unified type conversion
          final convertField = (dynamic value) => value is int 
              ? value 
              : int.tryParse(value.toString()) ?? 0;

          deviceMap['id'] = convertField(deviceMap['id']);
          deviceMap['office_id'] = deviceMap['office_id'] != null 
              ? convertField(deviceMap['office_id']) 
              : null;
          return deviceMap;
        }).where((d) => d['id'] != 0).toList(); // Filter invalid entries
        
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        _lastPage = int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1;
        _total = int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
        _perPage = int.tryParse(pagination['per_page']?.toString() ?? '10') ?? 10;
        debugPrint('Filters applied successfully. Found ${_devices.length} devices');
      } else {
        debugPrint('Failed to apply filters: ${result['message']}');
        _error = result['message'];
      }
    } catch (e) {
      debugPrint('Exception while applying filters: $e');
      _error = 'Failed to apply filters: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDevice(Map<String, dynamic> deviceData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _deviceService.createDevice(deviceData);
      if (result['success']) {
        _devices.add(result['device']);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _error = 'Failed to create device';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDevice(int id, Map<String, dynamic> deviceData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _deviceService.updateDevice(id, deviceData);
      if (result['success']) {
        final index = _devices.indexWhere((device) => device['id'] == id);
        if (index != -1) {
          _devices[index] = result['device'];
          notifyListeners();
        }
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _error = 'Failed to update device';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDevice(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _deviceService.deleteDevice(id);
      if (result['success']) {
        _devices.removeWhere((device) => device['id'] == id);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete device';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  set devices(List<Map<String, dynamic>> value) {
    _devices = value;
    notifyListeners();
  }
}