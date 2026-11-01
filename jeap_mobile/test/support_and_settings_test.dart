import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jeap_mobile/features/account/presentation/screens/help_support_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notification_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('HelpSupportScreen Tests', () {
    testWidgets('Renders header, contact rows, and FAQ items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Direct Contact Channels'), findsOneWidget);
      expect(find.text('support@jeap.store'), findsOneWidget);
      expect(find.text('+63 2 8123 4567'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I track my order?'), findsOneWidget);
    });

    testWidgets('Search query filters FAQ items correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'cancel');
      await tester.pumpAndSettle();

      expect(
          find.text('Can I cancel an order after placing it?'), findsOneWidget);
      expect(find.text('How do I track my order?'), findsNothing);
    });
  });

  group('NotificationSettingsScreen Tests', () {
    testWidgets('Renders all notification preferences and responds to toggles',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Order Tracking & Delivery'), findsOneWidget);
      expect(find.text('Direct Messages & Chat'), findsOneWidget);
      expect(find.text('Sound Notification'), findsOneWidget);

      // Find switches and toggle
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });
  });
}
