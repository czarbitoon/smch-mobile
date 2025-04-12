import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/office_service.dart';
import 'auth_provider.dart';
import 'device_provider.dart';
import 'device_report_provider.dart';
import 'office_provider.dart';
import 'reports_provider.dart';
import 'theme_provider.dart';

// Service Providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: AppConfig.apiUrl);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiServiceProvider));
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.watch(apiServiceProvider));
});

final officeServiceProvider = Provider<OfficeService>((ref) {
  return OfficeService(ref.watch(apiServiceProvider));
});

// State Providers
final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider();
});

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider(ref.watch(authServiceProvider));
});

final deviceProvider = ChangeNotifierProvider<DeviceProvider>((ref) {
  return DeviceProvider(ref.watch(deviceServiceProvider));
});

final officeProvider = ChangeNotifierProvider<OfficeProvider>((ref) {
  return OfficeProvider(ref.watch(officeServiceProvider));
});

final reportsProvider = ChangeNotifierProvider<ReportsProvider>((ref) {
  return ReportsProvider(ref.watch(apiServiceProvider));
});

final deviceReportProvider = ChangeNotifierProvider<DeviceReportProvider>((ref) {
  return DeviceReportProvider(ref.watch(apiServiceProvider));
}); 