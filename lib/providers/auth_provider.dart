import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'base_provider.dart';
import 'dart:io';
import 'dart:async' show unawaited;

class AuthProvider extends BaseProvider {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  UserModel? _user;

  bool get isAuthenticated => _userData != null;
  Map<String, dynamic>? get userData => _userData;
  UserModel? get user => _user;

  // Role-based access control getters
  int get userType => _user?.type ?? 0;
  bool get isAdmin => userType >= 2;
  bool get isStaff => userType == 1;

  AuthProvider() {
    _initializeAuth();
  }

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

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData, File? profileImage) async {
    if (_isInitializing || _isLoadingProfile) {
      return {'success': false, 'message': 'Profile update operation in progress'};
    }

    setLoading(true);
    clearError();

    try {
      final result = await _authService.updateUserProfile(profileData);
      
      if (result['success']) {
        if (profileImage != null) {
          // TODO: Implement image upload when backend endpoint is ready
          // For now, we'll just return success
        }
        
        if (!_isLoadingProfile) {
          await _loadUserProfile();
        }
      }
      
      return result;
    } catch (e) {
      setError('Failed to update profile: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    } finally {
      setLoading(false);
    }
  }
  }