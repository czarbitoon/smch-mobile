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
        debugPrint('loadOffices: Starting to fetch offices');
        final result = await _officeService.getOffices();
        debugPrint('loadOffices: Received API response with success=${result['success']}');

        if (result['success'] == true) {
          if (result['offices'] == null) {
            debugPrint('loadOffices: No offices data in response');
            _offices = [];
            return;
          }

          try {
            final officesList = List<Map<String, dynamic>>.from(result['offices']);
            debugPrint('loadOffices: Processing ${officesList.length} offices');

            _offices = officesList.where((office) {
              if (office == null) {
                debugPrint('loadOffices: Found null office entry');
                return false;
              }

              final bool isValid = office['id'] != null && 
                                 office['name'] != null && 
                                 office['name'].toString().isNotEmpty;

              if (!isValid) {
                debugPrint('loadOffices: Invalid office data: id=${office['id']}, name=${office['name']}');
              }

              return isValid;
            }).toList();

            debugPrint('loadOffices: Successfully processed ${_offices.length} valid offices');
            if (_offices.length != officesList.length) {
              debugPrint('loadOffices: Filtered out ${officesList.length - _offices.length} invalid offices');
            }
          } catch (e) {
            debugPrint('loadOffices: Error processing office data: $e');
            setError('Invalid office data format');
            _offices = [];
          }
        } else {
          final errorMessage = result['message'] ?? 'Failed to load offices';
          debugPrint('loadOffices: API returned error: $errorMessage');
          setError(errorMessage);
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