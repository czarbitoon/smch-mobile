import 'package:flutter/material.dart';
import '../services/office_service.dart';

class OfficeProvider extends ChangeNotifier {
  final OfficeService _officeService = OfficeService();
  List<Map<String, dynamic>> _offices = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get offices => _offices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  set offices(List<Map<String, dynamic>> value) {
    _offices = value;
    notifyListeners();
  }

  Future<void> loadOffices() async {
    if (_isLoading) {
      debugPrint('loadOffices: Already loading, skipping request');
      return;
    }
    
    debugPrint('loadOffices: Starting to load offices...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('loadOffices: Calling office service...');
      final result = await _officeService.getOffices();
      debugPrint('loadOffices: Received response: $result');

      if (result['success'] == true && result['offices'] != null) {
        debugPrint('loadOffices: Successfully received offices data');
        final officesList = List<Map<String, dynamic>>.from(result['offices']);
        _offices = officesList.where((office) => 
          office != null && 
          office['id'] != null && 
          office['name'] != null && 
          office['name'].toString().isNotEmpty
        ).toList();
        debugPrint('loadOffices: Transformed ${_offices.length} valid offices');
        debugPrint('loadOffices: Office data: ${_offices.map((o) => "${o['id']}: ${o['name']}").join(', ')}');
        _error = null;
      } else {
        debugPrint('loadOffices: API returned error: ${result['message']}');
        _error = result['message'] ?? 'Failed to load offices';
        _offices = [];
      }
    } catch (e) {
      debugPrint('loadOffices: Exception occurred: ${e.toString()}');
      _error = 'Connection error: ${e.toString()}';
      _offices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('loadOffices: Completed loading. Success: ${_error == null}');
    }
  }

  Future<bool> createOffice(Map<String, dynamic> officeData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _officeService.createOffice(officeData);
      if (result['success']) {
        _offices.add(result['office']);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _error = 'Failed to create office';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOffice(int id, Map<String, dynamic> officeData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _officeService.updateOffice(id, officeData);
      if (result['success']) {
        final index = _offices.indexWhere((office) => office['id'] == id);
        if (index != -1) {
          _offices[index] = result['office'];
          notifyListeners();
        }
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _error = 'Failed to update office';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOffice(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _officeService.deleteOffice(id);
      if (result['success']) {
        _offices.removeWhere((office) => office['id'] == id);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete office';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}