import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smch_mobile/providers/office_provider.dart';
import 'package:smch_mobile/screens/office_management_screen.dart';

void main() {
  group('OfficeManagementScreen', () {
    late OfficeProvider officeProvider;

    setUp(() {
      officeProvider = OfficeProvider();
    });

    testWidgets('renders loading indicator when loading', (WidgetTester tester) async {
      officeProvider.isLoading = true;

      await tester.pumpWidget(
        ChangeNotifierProvider<OfficeProvider>.value(
          value: officeProvider,
          child: const MaterialApp(
            home: OfficeManagementScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when there is an error', (WidgetTester tester) async {
      officeProvider.error = 'Test error message';
      officeProvider.isLoading = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<OfficeProvider>.value(
          value: officeProvider,
          child: const MaterialApp(
            home: OfficeManagementScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('shows office list when loaded successfully', (WidgetTester tester) async {
      officeProvider.offices = [
        {
          'id': 1,
          'name': 'Test Office',
          'location': 'Test Location',
          'manager': 'Test Manager',
          'status': 'Active'
        }
      ];
      officeProvider.isLoading = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<OfficeProvider>.value(
          value: officeProvider,
          child: const MaterialApp(
            home: OfficeManagementScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Office'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.text('Test Manager'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('opens add office dialog when add button is tapped', (WidgetTester tester) async {
      officeProvider.isLoading = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<OfficeProvider>.value(
          value: officeProvider,
          child: const MaterialApp(
            home: OfficeManagementScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add Office'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });
}