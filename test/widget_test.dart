// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smch_mobile/main.dart';
import 'package:smch_mobile/providers/auth_provider.dart';
import 'package:smch_mobile/providers/device_provider.dart';
import 'package:smch_mobile/providers/office_provider.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const MyApp(),
    ));

    // Verify that the app title is displayed
    expect(find.text('SMCH Mobile'), findsOneWidget);

    // Verify that the login screen is the initial screen
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
