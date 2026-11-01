import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/categories_screen.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';

void main() {
  group('Priority 2 — Global Sidebar Navigation & Drawer Tests', () {
    testWidgets('CategoriesScreen hamburger menu opens BuyerDrawer and highlights tab 1',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoriesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap hamburger menu in JeapAppBar
      final menuButton = find.byTooltip('Open Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should now be visible
      expect(find.byType(BuyerDrawer), findsOneWidget);
      expect(find.text('Categories'), findsWidgets);
    });

    testWidgets('CartScreen hamburger menu opens BuyerDrawer and highlights tab 2',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(initialItems: []),
        ),
      );
      await tester.pumpAndSettle();

      final menuButton = find.byTooltip('Open Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.byType(BuyerDrawer), findsOneWidget);
      expect(find.text('My Cart'), findsOneWidget);
    });

    testWidgets('OrdersScreen hamburger menu opens BuyerDrawer and highlights tab 3',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersScreen(initialOrders: []),
        ),
      );
      await tester.pumpAndSettle();

      final menuButton = find.byTooltip('Open Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.byType(BuyerDrawer), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);
    });

    testWidgets('AccountScreen hamburger menu opens BuyerDrawer and highlights tab 4',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AccountScreen(
            initialUser: {
              'id': 1,
              'name': 'Juan Dela Cruz',
              'email': 'buyer@jeap.test',
              'role': 'buyer',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final menuButton = find.byTooltip('Open Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.byType(BuyerDrawer), findsOneWidget);
      expect(find.text('Account Overview'), findsOneWidget);
    });

    testWidgets('BuyerHomeScreen allows opening drawer from every tab and switching between them',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BuyerHomeScreen(
            initialProducts: [],
            initialCartItems: [],
            initialOrders: [],
            initialUser: {
              'id': 1,
              'name': 'Juan Dela Cruz',
              'email': 'buyer@jeap.test',
              'role': 'buyer',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0: Home -> open drawer
      final homeMenu = find.byTooltip('Navigation Menu');
      expect(homeMenu, findsOneWidget);
      await tester.tap(homeMenu);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerDrawer), findsOneWidget);

      // Tap 'Categories' in drawer
      await tester.tap(find.descendant(of: find.byType(BuyerDrawer), matching: find.text('Categories')));
      await tester.pumpAndSettle();

      // Drawer closed, now on Tab 1 (Categories)
      expect(find.byType(BuyerDrawer), findsNothing);
      expect(find.text('All Categories'), findsOneWidget);

      // Tab 1: Categories -> open drawer
      final catMenu = find.byTooltip('Open Menu');
      expect(catMenu, findsOneWidget);
      await tester.tap(catMenu);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerDrawer), findsOneWidget);

      // Tap 'My Cart' in drawer
      await tester.tap(find.descendant(of: find.byType(BuyerDrawer), matching: find.text('My Cart')));
      await tester.pumpAndSettle();

      // Drawer closed, now on Tab 2 (Cart)
      expect(find.byType(BuyerDrawer), findsNothing);

      // Tab 2: Cart -> open drawer
      final cartMenu = find.byTooltip('Open Menu');
      expect(cartMenu, findsOneWidget);
      await tester.tap(cartMenu);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerDrawer), findsOneWidget);

      // Tap 'My Orders' in drawer
      await tester.tap(find.descendant(of: find.byType(BuyerDrawer), matching: find.text('My Orders')));
      await tester.pumpAndSettle();

      // Drawer closed, now on Tab 3 (Orders)
      expect(find.byType(BuyerDrawer), findsNothing);
      expect(find.text('To Pay'), findsOneWidget);

      // Tab 3: Orders -> open drawer
      final ordersMenu = find.byTooltip('Open Menu');
      expect(ordersMenu, findsOneWidget);
      await tester.tap(ordersMenu);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerDrawer), findsOneWidget);

      // Tap 'Account Overview' in drawer
      await tester.tap(find.descendant(of: find.byType(BuyerDrawer), matching: find.text('Account Overview')));
      await tester.pumpAndSettle();

      // Drawer closed, now on Tab 4 (Account)
      expect(find.byType(BuyerDrawer), findsNothing);

      // Tab 4: Account -> open drawer
      final accountMenu = find.byTooltip('Open Menu');
      expect(accountMenu, findsOneWidget);
      await tester.tap(accountMenu);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerDrawer), findsOneWidget);
    });
  });
}
