import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'base_provider.dart';
import 'dart:io';
import 'dart:async' show unawaited;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userData;
  
  AuthProvider([AuthService? authService]) : _authService = authService ?? AuthService();

  String get apiBaseUrl => _authService.baseUrl;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userData != null;
  Map<String, dynamic>? get userData => _userData;

  // Role-based access control getters
  int get userType => _user?.role == 'admin' ? 1 : (_user?.role == 'staff' ? 2 : 0);
  bool get isAdmin => userType >= 2;
  bool get isStaff => userType == 1;

  bool _isInitializing = false;
  bool _isLoadingProfile = false;

  Future<void> _initializeAuth() async {
    if (_isInitializing) return;
    _isInitializing = true;
    clearError();

    try {
      _userData = await _authService.getCurrentUser();
      if (_userData != null && !_isLoadingProfile) {
        await _loadUserProfile();
      }
    } catch (e) {
      setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadUserProfile() async {
    if (_isLoadingProfile) return;
    _isLoadingProfile = true;
    clearError();

    try {
      final result = await _authService.getUserProfile();
      if (result['success'] && result['data'] != null) {
        final userData = result['data'];
        if (userData['user'] != null) {
          _user = UserModel.fromJson(userData['user']);
        }
      }
    } catch (e) {
      setError('Failed to load user profile: ${e.toString()}');
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getOffices() async {
    if (_isInitializing || _isLoadingProfile) {
      return [];
    }

    try {
      return await _authService.getOffices();
    } catch (e) {
      setError('Failed to fetch offices: ${e.toString()}');
      return [];
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, int type, String officeId) async {
    if (_isInitializing || _isLoadingProfile) {
      return {'success': false, 'message': 'Authentication operation in progress'};
    }

    setLoading(true);
    clearError();

    try {
      final result = await _authService.register(name, email, password, type, officeId);
      return result;
    } catch (e) {
      setError('Registration failed: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (_isInitializing || _isLoadingProfile) {
      return {'success': false, 'message': 'Authentication operation in progress'};
    }

    setLoading(true);
    clearError();

    try {
      final result = await _authService.login(email, password);
      if (result['success']) {
        _userData = result['user'];
        
        if (!_isLoadingProfile) {
          await _loadUserProfile();
        }
        
        // Pre-fetch data in parallel after successful login
        if (!_isInitializing && !_isLoadingProfile) {
          unawaited(Future.wait([
            _authService.getDevices(),
            _authService.getReports()
          ]));
        }
      }
      return result;
    } catch (e) {
      setError('Login failed: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    } finally {
      setLoading(false);
    }
  }

  Future<bool> logout() async {
    if (_isInitializing || _isLoadingProfile) {
      return false;
    }

    setLoading(true);
    clearError();

    try {
      final success = await _authService.logout();
      if (success) {
        _user = null;
        _userData = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      setError('Logout failed: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Upload image if provided
      if (userData['image'] != null && userData['image'] is File) {
        final imageFile = userData['image'] as File;
        final result = await _uploadProfileImage(userData['id'], imageFile.path);
        if (result) {
          userData.remove('image');
        }
      }

      final response = await _authService.updateUserProfile(userData);
      
      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']);
        _error = null;
        return true;
      }
      
      _error = response['message'] ?? 'Failed to update profile';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _uploadProfileImage(int userId, String imagePath) async {
    try {
      final response = await _authService.uploadProfileImage(userId, imagePath);
      return response['success'] == true;
    } catch (e) {
      _error = 'Failed to upload profile image: $e';
      return false;
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
}