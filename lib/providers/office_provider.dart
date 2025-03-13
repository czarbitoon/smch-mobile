import 'package:flutter/material.dart';
import '../services/office_service.dart';
import 'base_provider.dart';

class OfficeProvider extends BaseProvider {
  final OfficeService _officeService = OfficeService();
  List<Map<String, dynamic>> _offices = [];

  List<Map<String, dynamic>> get offices => _offices;

  Future<void> loadOffices() async {
    await handleAsync(
      () async {
        final result = await _officeService.getOffices();

        if (result['success'] == true && result['offices'] != null) {
          final officesList = List<Map<String, dynamic>>.from(result['offices']);
          _offices = officesList.where((office) => 
            office != null && 
            office['id'] != null && 
            office['name'] != null && 
            office['name'].toString().isNotEmpty
          ).toList();
          debugPrint('loadOffices: Transformed ${_offices.length} valid offices');
          debugPrint('loadOffices: Office data: ${_offices.map((o) => "${o['id']}: ${o['name']}").join(', ')}');
        } else {
          debugPrint('loadOffices: API returned error: ${result['message']}');
          setError(result['message'] ?? 'Failed to load offices');
          _offices = [];
        }
      },
      errorMessage: 'Failed to load offices',
    );
  }

  Future<bool> createOffice(Map<String, dynamic> officeData) async {
    return await handleAsync(
      () async {
        final result = await _officeService.createOffice(officeData);
        if (result['success']) {
          _offices.add(result['office']);
          notifyListeners();
          return true;
        } else {
          setError(result['message']);
          return false;
        }
      },
      errorMessage: 'Failed to create office',
    );
  }

  Future<bool> updateOffice(int id, Map<String, dynamic> officeData) async {
    return await handleAsync(
      () async {
        final result = await _officeService.updateOffice(id, officeData);
        if (result['success']) {
          final index = _offices.indexWhere((office) => office['id'] == id);
          if (index != -1) {
            _offices[index] = result['office'];
            notifyListeners();
          }
          return true;
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to update office',
    );
  }

  Future<bool> deleteOffice(int id) async {
    return await handleAsync(
      () async {
        final result = await _officeService.deleteOffice(id);
        if (result['success']) {
          _offices.removeWhere((office) => office['id'] == id);
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message']);
        }
      },
      errorMessage: 'Failed to delete office',
    );
  }
}