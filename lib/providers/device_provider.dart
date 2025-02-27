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
      if (result['success']) {
        debugPrint('Successfully received devices data');
        final data = result['data'];
        _devices = (data['data'] as List).map((device) {
          var deviceMap = Map<String, dynamic>.from(device);
          // Ensure ID is an integer
          deviceMap['id'] = int.tryParse(deviceMap['id'].toString()) ?? deviceMap['id'];
          // Ensure office_id is an integer if it exists
          if (deviceMap['office_id'] != null) {
            deviceMap['office_id'] = int.tryParse(deviceMap['office_id'].toString()) ?? deviceMap['office_id'];
          }
          return deviceMap;
        }).toList();
        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;
        _total = data['total'] ?? 0;
        _perPage = data['per_page'] ?? 10;
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