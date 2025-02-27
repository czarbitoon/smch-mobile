import 'package:flutter/material.dart';
import '../services/device_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _deviceService.getDevices();
      if (result['success']) {
        _devices = List<Map<String, dynamic>>.from(result['devices']);
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Failed to load devices';
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
}