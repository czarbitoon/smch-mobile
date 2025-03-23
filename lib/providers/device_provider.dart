import 'package:flutter/material.dart';
import '../services/device_service.dart';
import 'base_provider.dart';

class DeviceProvider extends BaseProvider {
  final DeviceService _deviceService = DeviceService();
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _deviceTypes = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 10;
  int _total = 0;

  List<Map<String, dynamic>> get devices => _devices;
  List<Map<String, dynamic>> get deviceTypes => _deviceTypes;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;

  static const _cacheTimeout = Duration(minutes: 5);
  DateTime? _lastFetchTime;

  Future<void> loadDevices({int? page}) async {
    // Return cached data if within timeout
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheTimeout &&
        _devices.isNotEmpty) {
      return;
    }

    await handleAsync(
      () async {
        final result = await _deviceService.getDevices(page: page ?? _currentPage);
        
        if (result['status'] == 401) {
          _devices = [];
          throw Exception(result['message']);
        }

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
            deviceMap['office'] = deviceMap['office']?['name'] ?? 'No Office';
            deviceMap['type'] = deviceMap['type']?['name'] ?? deviceMap['device_subcategory']?['device_type']?['name'] ?? 'Unknown';
            deviceMap['subcategory_id'] = deviceMap['subcategory_id'] != null
                ? convertField(deviceMap['subcategory_id'])
                : null;
            deviceMap['type_id'] = deviceMap['device_subcategory']?['device_type']?['id'] != null
                ? convertField(deviceMap['device_subcategory']['device_type']['id'])
                : null;

            return deviceMap;
          }).where((d) => d['id'] != 0).toList(); // Filter invalid entries
          
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
          _currentPage = int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1;
          _lastPage = int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1;
          _total = int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
          _perPage = int.tryParse(pagination['per_page']?.toString() ?? '10') ?? 10;

        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to load devices',
    );
  }

  Future<void> loadDeviceTypes() async {
    await handleAsync(
      () async {
        final result = await _deviceService.getDeviceTypes();
        if (result['success']) {
          _deviceTypes = List<Map<String, dynamic>>.from(result['types']);
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to load device types',
    );
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    await handleAsync(
      () async {
        final result = await _deviceService.getDevices(filters: filters);
        if (result['status'] == 401) {
          _devices = [];
          throw Exception(result['message']);
        }

        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as Map<String, dynamic>;
          final devicesData = data['devices'] as List? ?? [];
          final newDevices = devicesData.map((device) {
            final deviceMap = Map<String, dynamic>.from(device);
            
            final convertField = (dynamic value) => value is int 
                ? value 
                : int.tryParse(value.toString()) ?? 0;

            deviceMap['id'] = convertField(deviceMap['id']);
            deviceMap['office_id'] = deviceMap['office_id'] != null 
                ? convertField(deviceMap['office_id']) 
                : null;
            deviceMap['office'] = deviceMap['office']?['name'] ?? 'No Office';
            deviceMap['type'] = deviceMap['type']?['name'] ?? deviceMap['device_subcategory']?['device_type']?['name'] ?? 'Unknown';
            deviceMap['subcategory_id'] = deviceMap['subcategory_id'] != null
                ? convertField(deviceMap['subcategory_id'])
                : null;
            deviceMap['type_id'] = deviceMap['device_subcategory']?['device_type']?['id'] != null
                ? convertField(deviceMap['device_subcategory']['device_type']['id'])
                : null;

            return deviceMap;
          }).where((d) => d['id'] != 0).toList();
          
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
          final newCurrentPage = int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1;
          final newLastPage = int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1;
          final newTotal = int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
          final newPerPage = int.tryParse(pagination['per_page']?.toString() ?? '10') ?? 10;

          // Update state atomically
          _devices = newDevices;
          _currentPage = newCurrentPage;
          _lastPage = newLastPage;
          _total = newTotal;
          _perPage = newPerPage;
          _lastFetchTime = DateTime.now();
          notifyListeners();
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to apply filters',
    );
  }

  Future<bool> createDevice(Map<String, dynamic> deviceData) async {
    return await handleAsync(
      () async {
        final result = await _deviceService.createDevice(deviceData);
        if (result['success']) {
          _devices.add(result['device']);
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to create device',
    );
  }

  Future<bool> updateDevice(int id, Map<String, dynamic> deviceData) async {
    return await handleAsync(
      () async {
        final result = await _deviceService.updateDevice(id, deviceData);
        if (result['success']) {
          final index = _devices.indexWhere((device) => device['id'] == id);
          if (index != -1) {
            _devices[index] = result['device'];
            notifyListeners();
          }
          return true;
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to update device',
    );
  }

  Future<bool> deleteDevice(int id) async {
    return await handleAsync(
      () async {
        final result = await _deviceService.deleteDevice(id);
        if (result['success']) {
          _devices.removeWhere((device) => device['id'] == id);
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to delete device',
    );
  }

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

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
    if (page >= 1 && page <= _lastPage) {
      await loadDevices(page: page);
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