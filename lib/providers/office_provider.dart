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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _officeService.getOffices();
      if (result['success']) {
        _offices = List<Map<String, dynamic>>.from(result['offices']);
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Failed to load offices';
    } finally {
      _isLoading = false;
      notifyListeners();
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