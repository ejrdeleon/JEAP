import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/data/mock_data.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/account/models/address.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/home_tab_screen.dart';
import 'package:jeap_mobile/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/order_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthSession.instance.clear();
  });

  testWidgets('JEAP-4: 01_login screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/01_login.png'),
    );
  });

  testWidgets('JEAP-21: 02_product_catalog screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeTabScreen(
          initialProducts: MockData.products,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeTabScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/02_product_catalog.png'),
    );
  });

  testWidgets('JEAP-23: 03_cart screenshot', (tester) async {
    AuthSession.instance.setUser({
      'id': 1,
      'name': 'Maria Santos',
      'email': 'buyer@jeap.test',
      'role': 'buyer',
    });

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cartItems = [
      BuyerCartItem(
        id: 1,
        productId: '1',
        productName: 'MacBook Air M2 (Midnight, 256GB)',
        price: 54990.00,
        quantity: 1,
        sellerName: 'Apple Authorized Reseller PH',
        selected: true,
      ),
      BuyerCartItem(
        id: 2,
        productId: '2',
        productName: 'Sony WH-1000XM5 Wireless Headphones (Silver)',
        price: 18990.00,
        quantity: 2,
        sellerName: 'Sony Electronics Store',
        selected: true,
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
      matchesGoldenFile('../../screenshots/jeap_mobile/03_cart.png'),
    );
  });

  testWidgets('JEAP-23: 04_checkout screenshot', (tester) async {
    AuthSession.instance.setUser({
      'id': 1,
      'name': 'Maria Santos',
      'email': 'buyer@jeap.test',
      'role': 'buyer',
    });

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checkoutAddresses = [
      const Address(
        id: 1,
        label: 'Home',
        recipientName: 'Maria Santos',
        phone: '09171234567',
        streetLine: 'Unit 402, Emerald Tower, 123 Ayala Ave',
        barangay: 'San Lorenzo',
        city: 'Makati City',
        province: 'Metro Manila',
        zipCode: '1223',
        isDefault: true,
      ),
    ];

    final checkoutItems = [
      BuyerCartItem(
        id: 1,
        productId: '1',
        productName: 'MacBook Air M2 (Midnight, 256GB)',
        price: 54990.00,
        quantity: 1,
        sellerName: 'Apple Authorized Reseller PH',
        selected: true,
      ),
      BuyerCartItem(
        id: 2,
        productId: '2',
        productName: 'Sony WH-1000XM5 Wireless Headphones (Silver)',
        price: 18990.00,
        quantity: 2,
        sellerName: 'Sony Electronics Store',
        selected: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: CheckoutScreen(
          items: checkoutItems,
          subtotal: 92970.00,
          initialAddresses: checkoutAddresses,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CheckoutScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/04_checkout.png'),
    );
  });

  testWidgets('JEAP-24: 05_order_tracking screenshot', (tester) async {
    AuthSession.instance.setUser({
      'id': 1,
      'name': 'Maria Santos',
      'email': 'buyer@jeap.test',
      'role': 'buyer',
    });

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleOrder = Order(
      id: '101',
      orderNumber: 'JEAP-2026-8842',
      status: OrderStatus.outForDelivery,
      subtotal: 92970.00,
      discount: 0.00,
      deliveryFee: 50.00,
      total: 93020.00,
      deliveryAddress:
          'Maria Santos | 09171234567\nUnit 402, Emerald Tower, 123 Ayala Ave, San Lorenzo, Makati City, Metro Manila 1223',
      paymentMethod: 'Cash on Delivery (COD)',
      createdAt: DateTime(2026, 10, 28, 14, 30),
      items: [
        OrderItem(
          productId: '1',
          productName: 'MacBook Air M2 (Midnight, 256GB)',
          price: 54990.00,
          quantity: 1,
          variations: {'Color': 'Midnight', 'Storage': '256GB'},
        ),
        OrderItem(
          productId: '2',
          productName: 'Sony WH-1000XM5 Wireless Headphones',
          price: 18990.00,
          quantity: 2,
          variations: {'Color': 'Silver'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: OrderDetailScreen(order: sampleOrder),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OrderDetailScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/05_order_tracking.png'),
    );
  });
}
