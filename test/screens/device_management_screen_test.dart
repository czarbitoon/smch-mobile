import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smch_mobile/providers/device_provider.dart';
import 'package:smch_mobile/providers/office_provider.dart';
import 'package:smch_mobile/screens/device_management_screen.dart';

void main() {
  group('DeviceManagementScreen', () {
    late DeviceProvider deviceProvider;
    late OfficeProvider officeProvider;

    setUp(() {
      deviceProvider = DeviceProvider();
      officeProvider = OfficeProvider();
    });

    testWidgets('renders loading indicator when loading', (WidgetTester tester) async {
      deviceProvider.isLoading = true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
            ChangeNotifierProvider<OfficeProvider>.value(value: officeProvider),
          ],
          child: const MaterialApp(
            home: DeviceManagementScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when there is an error', (WidgetTester tester) async {
      deviceProvider.error = 'Test error message';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
            ChangeNotifierProvider<OfficeProvider>.value(value: officeProvider),
          ],
          child: const MaterialApp(
            home: DeviceManagementScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('shows device list when loaded successfully', (WidgetTester tester) async {
      deviceProvider.devices = [
        {
          'id': 1,
          'name': 'Test Device',
          'type': 'Test Type',
          'status': 'Available',
          'office_id': 1
        }
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
            ChangeNotifierProvider<OfficeProvider>.value(value: officeProvider),
          ],
          child: const MaterialApp(
            home: DeviceManagementScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('Test Type'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('opens add device dialog when FAB is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
            ChangeNotifierProvider<OfficeProvider>.value(value: officeProvider),
          ],
          child: const MaterialApp(
            home: DeviceManagementScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add Device'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });
  });
}