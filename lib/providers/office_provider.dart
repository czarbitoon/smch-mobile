import 'package:flutter/material.dart';
import '../services/office_service.dart';

class OfficeProvider extends ChangeNotifier {
  final OfficeService _officeService;
  List<Map<String, dynamic>> _offices = [];
  Map<String, dynamic>? _currentOffice;
  bool _isLoading = false;
  String? _error;

  OfficeProvider(this._officeService);

  List<Map<String, dynamic>> get offices => _offices;
  Map<String, dynamic>? get currentOffice => _currentOffice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOffices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _officeService.getOffices();
      if (response.success) {
        _offices = response.offices;
        _error = null;
      } else {
        _error = response.message ?? 'Failed to get offices';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> getOfficeDetails(int officeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _officeService.getOffice(officeId);
      if (response.success && response.office != null) {
        _currentOffice = response.office;
        _error = null;
        return true;
      }
      _error = response.message ?? 'Failed to get office details';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
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
      final response = await _officeService.createOffice(officeData);
      if (response.success) {
        await loadOffices();
        return true;
      }
      _error = response.message ?? 'Failed to create office';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOffice(int officeId, Map<String, dynamic> officeData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _officeService.updateOffice(officeId, officeData);
      if (response.success) {
        await loadOffices();
        if (_currentOffice != null && _currentOffice!['id'] == officeId) {
          _currentOffice = response.office;
        }
        return true;
      }
      _error = response.message ?? 'Failed to update office';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOffice(int officeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _officeService.deleteOffice(officeId);
      if (response.success) {
        if (_currentOffice != null && _currentOffice!['id'] == officeId) {
          _currentOffice = null;
        }
        await loadOffices();
        return true;
      }
      _error = response.message ?? 'Failed to delete office';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentOffice() {
    _currentOffice = null;
    notifyListeners();
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