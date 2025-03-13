import 'package:flutter/material.dart';

class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<T> handleAsync<T>(
    Future<T> Function() operation, {
    String errorMessage = 'Operation failed',
  }) async {
    if (_isLoading) return Future.error('Operation in progress');

    setLoading(true);
    clearError();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      setError('$errorMessage: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}