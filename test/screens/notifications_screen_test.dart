import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smch_mobile/providers/report_provider.dart';
import 'package:smch_mobile/screens/notifications_screen.dart';

void main() {
  group('NotificationsScreen', () {
    late ReportProvider reportProvider;

    setUp(() {
      reportProvider = ReportProvider();
    });

    testWidgets('renders loading indicator when loading', (WidgetTester tester) async {
      reportProvider.isLoading = true;

      await tester.pumpWidget(
        ChangeNotifierProvider<ReportProvider>.value(
          value: reportProvider,
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when there is an error', (WidgetTester tester) async {
      reportProvider.error = 'Test error message';

      await tester.pumpWidget(
        ChangeNotifierProvider<ReportProvider>.value(
          value: reportProvider,
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('shows notifications list when loaded successfully', (WidgetTester tester) async {
      reportProvider.notifications = [
        {
          'id': 1,
          'title': 'Test Notification',
          'message': 'Test Message',
          'created_at': '2024-01-01 12:00:00'
        }
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<ReportProvider>.value(
          value: reportProvider,
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Notification'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    testWidgets('shows clear all dialog when clear button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ReportProvider>.value(
          value: reportProvider,
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Clear All Notifications'), findsOneWidget);
      expect(find.text('Are you sure you want to clear all notifications?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}