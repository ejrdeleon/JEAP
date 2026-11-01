import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/data/mock_data.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/account/models/address.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/categories_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/category_products_screen.dart';
import 'package:jeap_mobile/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockUser = {
    'id': 1,
    'name': 'Juan Dela Cruz',
    'email': 'buyer@jeap.test',
    'role': 'buyer',
  };

  final List<BuyerCartItem> mockCartItems = [
    BuyerCartItem(
      id: 1,
      variantId: 101,
      productId: 'p1',
      productName: 'Shaork Robot Vacuum Cleaner',
      sellerName: 'JEAP Official Store',
      price: 325.00,
      quantity: 1,
      imageUrl: null,
      variations: {'Color': 'Midnight Black'},
    ),
    BuyerCartItem(
      id: 2,
      variantId: 102,
      productId: 'p2',
      productName: 'Durotan Manual Espresso Machine',
      sellerName: 'Kitchen Wonders Store',
      price: 489.00,
      quantity: 2,
      imageUrl: null,
      variations: {'Color': 'Silver Chrome'},
    ),
  ];

  final List<Order> mockOrders = [
    Order(
      id: '1001',
      orderNumber: 'JEAP-2026-1001',
      status: OrderStatus.outForDelivery,
      paymentMethod: 'Cash on Delivery',
      total: 1303.00,
      subtotal: 1253.00,
      deliveryFee: 50.00,
      discount: 0.0,
      deliveryAddress: '123 Rizal Boulevard, Santa Cruz, Laguna',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      items: [
        OrderItem(
          productId: 'p2',
          productName: 'Durotan Manual Espresso Machine',
          quantity: 2,
          price: 489.00,
        ),
        OrderItem(
          productId: 'p1',
          productName: 'Shaork Robot Vacuum Cleaner',
          quantity: 1,
          price: 325.00,
        ),
      ],
    ),
    Order(
      id: '1002',
      orderNumber: 'JEAP-2026-1002',
      status: OrderStatus.toPay,
      paymentMethod: 'Cash on Delivery',
      total: 699.00,
      subtotal: 649.00,
      deliveryFee: 50.00,
      discount: 0.0,
      deliveryAddress: 'Floor 5, JEAP Logistics Center, BGC, Taguig',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      items: [
        OrderItem(
          productId: 'p3',
          productName: 'iPad mini 2023 Wi-Fi 256GB',
          quantity: 1,
          price: 649.00,
        ),
      ],
    ),
  ];

  final List<Address> mockAddresses = [
    const Address(
      id: 1,
      label: 'Home',
      recipientName: 'Juan Dela Cruz',
      phone: '+63 917 123 4567',
      streetLine: '123 Rizal Boulevard, Brgy. San Antonio',
      barangay: 'San Antonio',
      city: 'Santa Cruz',
      province: 'Laguna',
      zipCode: '4009',
      isDefault: true,
    ),
    const Address(
      id: 2,
      label: 'Office',
      recipientName: 'Juan Dela Cruz',
      phone: '+63 917 123 4567',
      streetLine: 'Floor 5, JEAP Logistics Center, BGC',
      barangay: 'Fort Bonifacio',
      city: 'Taguig',
      province: 'Metro Manila',
      zipCode: '1630',
      isDefault: false,
    ),
  ];

  setUp(() {
    AuthSession.instance.setUser(mockUser);
  });

  testWidgets('01_home_professional', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BuyerHomeScreen(
          initialTabIndex: 0,
          initialProducts: MockData.products,
          initialCartItems: mockCartItems,
          initialOrders: mockOrders,
          initialUser: mockUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BuyerHomeScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/01_home_professional.png'),
    );
  });

  testWidgets('02_categories', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const CategoriesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CategoriesScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/02_categories.png'),
    );
  });

  testWidgets('03_cart_sidebar', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: CartScreen(initialItems: mockCartItems),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CartScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/03_cart_sidebar.png'),
    );
  });

  testWidgets('04_orders_sidebar', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: OrdersScreen(initialOrders: mockOrders),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OrdersScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/04_orders_sidebar.png'),
    );
  });

  testWidgets('05_account_sidebar', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AccountScreen(initialUser: mockUser),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AccountScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/05_account_sidebar.png'),
    );
  });

  testWidgets('06_navigation_drawer', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BuyerHomeScreen(
          initialTabIndex: 0,
          initialProducts: MockData.products,
          initialCartItems: mockCartItems,
          initialOrders: mockOrders,
          initialUser: mockUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Drawer
    final homeMenu = find.byTooltip('Navigation Menu');
    expect(homeMenu, findsOneWidget);
    await tester.tap(homeMenu);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BuyerHomeScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/06_navigation_drawer.png'),
    );
  });

  testWidgets('07_product_catalog', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testCategory = MockData.categories.first;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: CategoryProductsScreen(category: testCategory),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CategoryProductsScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/07_product_catalog.png'),
    );
  });

  testWidgets('08_checkout', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: CheckoutScreen(
          items: mockCartItems,
          subtotal: 1303.00,
          initialAddresses: mockAddresses,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CheckoutScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/08_checkout.png'),
    );
  });
}
