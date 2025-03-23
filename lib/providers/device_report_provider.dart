import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reports_provider.dart';

class DeviceReportProvider extends ReportsProvider {
  DeviceReportProvider() : super(ApiService());

  // Add any device-specific report functionality here if needed
  // For now, we're inheriting all functionality from ReportsProvider
}