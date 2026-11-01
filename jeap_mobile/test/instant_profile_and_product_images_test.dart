import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_avatar.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/home_tab_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1x1 transparent PNG data URI for local offline image testing
  const samplePngData =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  group('Section 1 — Instant Profile Photo Updates Unit & Widget Tests', () {
    test('ApiConfig.resolveImageUrl resolves /images/ correctly without duplicate /storage', () {
      final resolved = ApiConfig.resolveImageUrl('images/categories/cat-robot.png');
      expect(resolved, contains('/images/categories/cat-robot.png'));
      expect(resolved, isNot(contains('/storage/images/')));
    });

    test('ApiConfig.resolveImageUrl resolves /storage/products/ correctly', () {
      final resolved = ApiConfig.resolveImageUrl('storage/products/phone.jpg');
      expect(resolved, contains('/storage/products/phone.jpg'));
    });

    test('ApiConfig.resolveImageUrl cacheBust uses stable avatarVersion until bumped', () {
      final initialVersion = ApiConfig.avatarVersion;
      final url1 = ApiConfig.resolveImageUrl('http://192.168.1.7:8080/media/avatars/4', cacheBust: true);
      expect(url1, contains('v=$initialVersion'));

      ApiConfig.bumpAvatarVersion();
      final bumpedVersion = ApiConfig.avatarVersion;
      expect(bumpedVersion, equals(initialVersion + 1));

      final url2 = ApiConfig.resolveImageUrl('http://192.168.1.7:8080/media/avatars/4', cacheBust: true);
      expect(url2, contains('v=$bumpedVersion'));
    });

    testWidgets('JeapAvatar reactively updates when avatarVersionNotifier is bumped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JeapAvatar(
              name: 'Ernest James De Leon',
              imageUrl: samplePngData,
              radius: 40,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(JeapAvatar), findsOneWidget);

      final initialVer = ApiConfig.avatarVersion;
      ApiConfig.bumpAvatarVersion();
      await tester.pump();

      expect(ApiConfig.avatarVersion, equals(initialVer + 1));
    });

    testWidgets('AccountScreen reacts immediately when AuthSession updates user profile photo', (tester) async {
      await AuthSession.instance.setUser({
        'id': 4,
        'name': 'Ernest James De Leon',
        'first_name': 'Ernest James',
        'last_name': 'De Leon',
        'email': 'ernest@example.com',
        'role': 'buyer',
        'avatar_url': null,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AccountScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Ernest James De Leon'), findsOneWidget);

      // Now simulate avatar update from upload
      await AuthSession.instance.setUser({
        'id': 4,
        'name': 'Ernest James De Leon',
        'first_name': 'Ernest James',
        'last_name': 'De Leon',
        'email': 'ernest@example.com',
        'role': 'buyer',
        'avatar_url': samplePngData,
      });
      ApiConfig.bumpAvatarVersion();
      await tester.pump();

      expect(find.byType(JeapAvatar), findsOneWidget);
    });
  });

  group('Section 2 — Complete Product Image Integration Tests', () {
    test('Product.fromJson parses image_url directly from backend response', () {
      final json = {
        'id': 12,
        'name': 'MacBook Air M2',
        'price': '999.00',
        'stock': 30,
        'image_url': 'http://192.168.1.7:8080/images/categories/cat-computers.png',
        'images': [
          {
            'id': 11,
            'product_id': 12,
            'path': 'images/categories/cat-computers.png',
            'url': 'http://192.168.1.7:8080/images/categories/cat-computers.png',
          }
        ],
      };

      final product = Product.fromJson(json);
      expect(product.imageUrl, contains('/images/categories/cat-computers.png'));
      expect(product.imageUrl, isNot(contains('/storage/images/')));
    });

    test('Product.fromJson falls back to images.first.path when image_url is missing', () {
      final json = {
        'id': 2,
        'name': 'Shaork Robot Vacuum',
        'price': '325.00',
        'stock': 15,
        'images': [
          {
            'id': 2,
            'product_id': 2,
            'path': 'images/categories/cat-robot.png',
          }
        ],
      };

      final product = Product.fromJson(json);
      expect(product.imageUrl, isNotNull);
      expect(product.imageUrl, contains('images/categories/cat-robot.png'));
    });

    testWidgets('JeapNetworkImage renders placeholder fallback when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JeapNetworkImage(
              imageUrl: null,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });

  group('Section 6 — Real Screenshot Generation on Galaxy S25 Viewport', () {
    testWidgets('profile_photo_updated screenshot', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await AuthSession.instance.setUser({
        'id': 4,
        'name': 'Ernest James De Leon',
        'first_name': 'Ernest James',
        'last_name': 'De Leon',
        'email': 'ernestjamesdeleon2005@gmail.com',
        'role': 'buyer',
        'avatar_url': samplePngData,
      });

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AccountScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/profile_photo_updated.png'),
      );
    });

    testWidgets('product_catalog_images screenshot', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const catalogSampleProducts = [
        Product(
          id: '12',
          name: 'MacBook Air M2',
          price: 999.00,
          rating: 4.9,
          reviewCount: 30,
          isNew: true,
          category: 'Computers',
          imageUrl: samplePngData,
        ),
        Product(
          id: '2',
          name: 'Shaork Robot Vacuum',
          price: 325.00,
          rating: 4.5,
          reviewCount: 18,
          isNew: false,
          category: 'Appliances',
          imageUrl: samplePngData,
        ),
        Product(
          id: '3',
          name: 'Durotan Manual Espresso Machine',
          price: 1250.00,
          rating: 4.8,
          reviewCount: 42,
          isNew: false,
          category: 'Appliances',
          imageUrl: samplePngData,
        ),
        Product(
          id: '4',
          name: 'Sona QLED Ultra HD 4K Smart TV',
          price: 24999.00,
          rating: 4.7,
          reviewCount: 56,
          isNew: true,
          category: 'Electronics',
          imageUrl: samplePngData,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const HomeTabScreen(
            initialProducts: catalogSampleProducts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeTabScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/product_catalog_images.png'),
      );
    });

    testWidgets('product_details_image screenshot', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const detailProduct = Product(
        id: '12',
        name: 'MacBook Air M2',
        price: 999.00,
        compareAtPrice: 1199.00,
        rating: 4.9,
        reviewCount: 30,
        isNew: true,
        category: 'Computers',
        description: 'Apple MacBook Air M2 chip, 13.6-inch Liquid Retina display, 8GB Unified Memory, 256GB SSD Storage, Space Gray.',
        imageUrl: samplePngData,
        stock: 30,
        brand: 'Apple',
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const ProductDetailScreen(
            product: detailProduct,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProductDetailScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/product_details_image.png'),
      );
    });

    testWidgets('cart_product_images screenshot', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await AuthSession.instance.setUser({
        'id': 4,
        'name': 'Ernest James De Leon',
        'email': 'ernest@example.com',
        'role': 'buyer',
      });

      final cartItems = [
        BuyerCartItem(
          id: 1,
          productId: '12',
          productName: 'MacBook Air M2',
          price: 999.00,
          quantity: 1,
          imageUrl: samplePngData,
          selected: true,
          sellerName: 'Apple PH Official Store',
        ),
        BuyerCartItem(
          id: 2,
          productId: '2',
          productName: 'Shaork Robot Vacuum',
          price: 325.00,
          quantity: 1,
          imageUrl: samplePngData,
          selected: true,
          sellerName: 'Home Solutions Store',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: CartScreen(initialItems: cartItems),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/cart_product_images.png'),
      );
    });
  });
}
