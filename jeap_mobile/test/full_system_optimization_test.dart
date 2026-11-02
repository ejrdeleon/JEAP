import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/data/mock_data.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/widgets/server_settings_sheet.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/categories_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/home_tab_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthSession.instance.clear();
  });

  group('Priority 1 — Responsive UI Tests', () {
    testWidgets('Renders on compact phone width (320px) without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeTabScreen(initialProducts: MockData.products),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeTabScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders on Samsung Galaxy S25 (412x915) standard phone layout', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders on tablet screen (800x1280) with NavigationRail and adaptive layout', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders with large text scaling without overflowing product cards', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testProduct = Product(
        id: 'p-scale-test',
        name: 'Apple MacBook Air M2 13.6-inch 512GB Storage',
        price: 79990.00,
        rating: 4.9,
        reviewCount: 320,
        isNew: true,
        category: 'Computers',
        description: 'Large text scaling responsiveness test product',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SizedBox(
                width: 170,
                height: 280,
                child: ProductCard(product: testProduct),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProductCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Two-line product titles in HomeTab product grid render without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const realSampleProducts = [
        Product(
          id: 'p-1',
          name: 'Shaork Robot Vacuum',
          price: 325.00,
          rating: 4.5,
          reviewCount: 12,
          isNew: false,
          category: 'Appliances',
        ),
        Product(
          id: 'p-2',
          name: 'Durotan Manual Espresso Machine',
          price: 1250.00,
          rating: 4.8,
          reviewCount: 34,
          isNew: false,
          category: 'Appliances',
        ),
        Product(
          id: 'p-3',
          name: 'Sona QLED Ultra HD 4K Smart TV',
          price: 24999.00,
          rating: 4.7,
          reviewCount: 88,
          isNew: true,
          category: 'Electronics',
        ),
        Product(
          id: 'p-4',
          name: 'iPad mini 2023 Wi-Fi 256GB',
          price: 34990.00,
          rating: 4.9,
          reviewCount: 110,
          isNew: false,
          category: 'Tablets',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeTabScreen(
            initialProducts: realSampleProducts,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Durotan Manual Espresso Machine'), findsOneWidget);
      expect(find.text('Sona QLED Ultra HD 4K Smart TV'), findsOneWidget);
      expect(find.text('iPad mini 2023 Wi-Fi 256GB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Priority 2 — Sidebar / Navigation Drawer Repair Tests', () {
    testWidgets('Tapping menu button on HomeTab opens BuyerDrawer', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BuyerDrawer), findsNothing);

      // Tap hamburger menu button
      final menuBtn = find.byTooltip('Navigation Menu');
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Drawer is now open
      expect(find.byType(BuyerDrawer), findsOneWidget);
      expect(find.text('SHOPPING'), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);
    });

    testWidgets('Tapping a drawer destination switches the tab and closes the drawer', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open drawer
      await tester.tap(find.byTooltip('Navigation Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BuyerDrawer), findsOneWidget);

      // Tap 'Categories' in drawer
      await tester.tap(find.widgetWithText(InkWell, 'Categories'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Drawer closed
      expect(find.byType(BuyerDrawer), findsNothing);
      // Switched to CategoriesScreen
      expect(find.byType(CategoriesScreen), findsOneWidget);
    });

    testWidgets('Menu button on CategoriesScreen opens the navigation drawer', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Categories via bottom nav icon
      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap menu button in CategoriesScreen app bar
      final menuBtn = find.byTooltip('Open Menu');
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BuyerDrawer), findsOneWidget);
    });
  });

  group('Priority 3 — Product Search Tests', () {
    testWidgets('SearchScreen renders initial state with popular search chips', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SearchScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Search JEAP Products'), findsOneWidget);
      expect(find.text('MacBook'), findsOneWidget);
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
    });

    testWidgets('Tapping MacBook suggestion updates query and initiates search', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SearchScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('MacBook'));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'MacBook');
    });

    testWidgets('Clearing search text restores initial state', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SearchScreen(initialQuery: 'MacBook'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final clearBtn = find.byIcon(Icons.clear);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Search JEAP Products'), findsOneWidget);
    });
  });

  group('Priority 4 — Automatic Server Selection Tests', () {
    test('ApiConfig candidateUrls contains local, emulator, LAN, and production', () {
      final candidates = ApiConfig.candidateUrls;
      expect(candidates, isNotEmpty);
      expect(candidates.any((u) => u.contains('127.0.0.1')), isTrue);
      expect(candidates.any((u) => u.contains('10.0.2.2')), isTrue);
      expect(candidates.any((u) => u.contains('192.168.1.7')), isTrue);
    });

    test('ApiConfig probeEndpoint handles unreachable ports cleanly without crashing', () async {
      final reachable = await ApiConfig.probeEndpoint(
        'http://127.0.0.1:59999/api/v1',
        timeout: const Duration(milliseconds: 150),
      );
      expect(reachable, isFalse);
    });

    testWidgets('ServerSettingsSheet renders Auto-Detect Server button', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ServerSettingsSheet()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Auto-Detect Server'), findsOneWidget);
      expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
    });
  });
}
