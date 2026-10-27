import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/widgets/google_sign_in_button.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/search_screen.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI/UX Fixes Unit & Widget Tests', () {
    testWidgets('GoogleSignInButton renders with correct vector logo and text',
        (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () => pressed = true,
              text: 'Continue with Google',
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.tap(find.byType(GoogleSignInButton));
      expect(pressed, isTrue);
    });

    test('AuthSession avatarUrl getter returns parsed url or null', () async {
      final session = AuthSession.instance;
      await session.setUser({
        'id': 1,
        'name': 'Test User',
        'avatar_url': 'https://jeap.ph/storage/avatars/1/photo.jpg'
      });
      expect(session.avatarUrl, 'https://jeap.ph/storage/avatars/1/photo.jpg');

      await session.setUser({'id': 1, 'name': 'Test User', 'avatar_url': ''});
      expect(session.avatarUrl, isNull);

      await session.setUser(null);
      expect(session.avatarUrl, isNull);
    });

    testWidgets(
        'OrdersScreen TabBar has tabAlignment start without awkward buffer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersScreen(),
        ),
      );

      final tabFinder = find.byType(TabBar);
      expect(tabFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabFinder);
      expect(tabBar.isScrollable, isTrue);
      expect(tabBar.tabAlignment, TabAlignment.start);
      expect(tabBar.padding, const EdgeInsets.symmetric(horizontal: 16));
    });

    testWidgets('SearchScreen renders responsive styled search container',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Search products in database...'), findsOneWidget);
    });

    testWidgets('JeapLogo renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JeapLogo(height: 32),
          ),
        ),
      );

      expect(find.byType(JeapLogo), findsOneWidget);
    });
  });
}
