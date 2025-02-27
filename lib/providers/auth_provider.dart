import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    _user = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      if (result['success']) {
        _user = result['user'];
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.logout();
      if (success) {
        _user = null;
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get userType => _user?['type'] ?? 0;
  bool get isAdmin => userType >= 2;
  bool get isStaff => userType == 1;
}