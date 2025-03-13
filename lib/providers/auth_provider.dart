import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'base_provider.dart';

class AuthProvider extends BaseProvider {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await handleAsync(
      () async {
        _user = await _authService.getCurrentUser();
      },
      errorMessage: 'Failed to initialize authentication',
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return handleAsync(
      () async {
        final result = await _authService.login(email, password);
        if (result['success']) {
          _user = result['user'];
        } else {
          setError(result['message']);
        }
        return result;
      },
      errorMessage: 'Login failed',
    );
  }

  Future<bool> logout() async {
    return handleAsync(
      () async {
        final success = await _authService.logout();
        if (success) {
          _user = null;
        }
        return success;
      },
      errorMessage: 'Logout failed',
    );
  }

  int get userType => _user?['type'] ?? 0;
  bool get isAdmin => userType >= 2;
  bool get isStaff => userType == 1;
}