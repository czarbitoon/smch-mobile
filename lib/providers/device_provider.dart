import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../models/device_model.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService;
  List<DeviceModel> _devices = [];
  List<Map<String, dynamic>> _deviceTypes = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 10;
  int _total = 0;
  DeviceModel? _currentDevice;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _filters;

  DeviceProvider(this._deviceService);

  List<DeviceModel> get devices => _devices;
  List<Map<String, dynamic>> get deviceTypes => _deviceTypes;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  DeviceModel? get currentDevice => _currentDevice;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get filters => _filters;

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.getDevices(filters: _filters);
      if (response.success) {
        _devices = response.data ?? [];
        _currentPage = 1;
        _lastPage = response.meta?.lastPage ?? 1;
        _total = response.meta?.total ?? 0;
        _error = null;
      } else {
        _error = response.message ?? 'Failed to get devices';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> nextPage() async {
    if (_currentPage < _lastPage) {
      _currentPage++;
      await loadDevices();
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadDevices();
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _lastPage) {
      _currentPage = page;
      await loadDevices();
    }
  }

  Future<void> loadDeviceTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.getDevices();
      if (response.success) {
        _deviceTypes = response.data?.map((device) => {
          'id': device.id,
          'name': device.type,
        }).toList() ?? [];
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDevice(DeviceModel device) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.createDevice(device);
      if (response.success) {
        await loadDevices();
        return true;
      }
      _error = response.message ?? 'Failed to create device';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDevice(int id, DeviceModel device) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.updateDevice(id, device);
      if (response.success) {
        await loadDevices();
        return true;
      }
      _error = response.message ?? 'Failed to update device';
      return false;
    } catch (e) {
      _error = e.toString();
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
      final response = await _deviceService.deleteDevice(id);
      if (response.success) {
        await loadDevices();
        return true;
      }
      _error = response.message ?? 'Failed to delete device';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DeviceModel?> getDeviceDetails(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.getDevice(id);
      if (response.success) {
        _currentDevice = response.data;
        _error = null;
        return response.data;
      }
      _error = response.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDeviceImage(int deviceId, String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.uploadDeviceImage(deviceId, imagePath);
      if (response.success) {
        final index = _devices.indexWhere((d) => d.id == deviceId);
        if (index != -1) {
          _devices[index] = _devices[index].copyWith(imageUrl: response.data?['image_url']);
          notifyListeners();
        }
        return true;
      }
      _error = response.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getDeviceImageUrl(int deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _deviceService.getDeviceImage(deviceId);
      if (response.success) {
        return response.data?['image_url'];
      }
      _error = response.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters(Map<String, dynamic> filters) {
    _filters = filters;
    _currentPage = 1;
    loadDevices();
  }

  void clearFilters() {
    _filters = null;
    _currentPage = 1;
    loadDevices();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}