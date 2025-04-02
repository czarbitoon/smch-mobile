import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  
  // Default theme mode is system
  ThemeMode _themeMode = ThemeMode.light;
  
  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Constructor - loads saved theme preference
  ThemeProvider() {
    // Constructor doesn't await the future
  }
  
  // Initialize theme - to be awaited in main
  Future<void> initTheme() async {
    await _loadThemePreference();
  }
  
  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themePreferenceKey);
    
    if (savedThemeMode != null) {
      _themeMode = _getThemeModeFromString(savedThemeMode);
      notifyListeners();
    }
  }
  
  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _getStringFromThemeMode(mode));
  }
  
  // Set theme mode and save preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _saveThemePreference(mode);
    notifyListeners();
  }
  
  // Convert ThemeMode to String for storage
  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      default:
        return 'light';
    }
  }
  
  // Convert String to ThemeMode
  ThemeMode _getThemeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
  
  // Helper methods to check current theme
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;
}