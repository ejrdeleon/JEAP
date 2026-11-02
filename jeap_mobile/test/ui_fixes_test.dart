import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/widgets/google_sign_in_button.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
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
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
      expect(find.text('Search products (e.g. MacBook)...'), findsOneWidget);
    });

    testWidgets('ProductCard renders 2-line title without bottom overflow on mobile screen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75; // Galaxy S25 density (~392.7 logical width)
      addTearDown(() => tester.view.resetPhysicalSize());

      final longTitleProducts = [
        const Product(
          id: 'p1',
          name: 'Shaork Robot Vacuum',
          price: 325.00,
          rating: 0.0,
          reviewCount: 0,
        ),
        const Product(
          id: 'p2',
          name: 'Durotan Manual Espresso Machine',
          price: 489.00,
          rating: 0.0,
          reviewCount: 0,
        ),
        const Product(
          id: 'p3',
          name: 'Sona QLED Ultra HD 4K Smart TV',
          price: 1759.00,
          rating: 0.0,
          reviewCount: 0,
        ),
        const Product(
          id: 'p4',
          name: 'iPad mini 2023 Wi-Fi 256GB',
          price: 699.00,
          rating: 0.0,
          reviewCount: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: longTitleProducts.length,
              itemBuilder: (_, i) => ProductCard(product: longTitleProducts[i]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Shaork Robot Vacuum'), findsOneWidget);
      expect(find.text('Durotan Manual Espresso Machine'), findsOneWidget);
      expect(find.text('Sona QLED Ultra HD 4K Smart TV'), findsOneWidget);
      expect(find.text('iPad mini 2023 Wi-Fi 256GB'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
