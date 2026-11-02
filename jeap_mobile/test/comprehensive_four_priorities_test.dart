import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:jeap_mobile/features/location/services/location_service.dart';
import 'package:jeap_mobile/features/logistics/models/logistics_parcel.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/logistics_dashboard_screen.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/logistics_scanner_screen.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/scan_result_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_documents_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_fleet_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_vehicle_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phoneSize = Size(412, 915);

  group('Priority 1 - Philippine Address PSGC System', () {
    test('LocationService returns Laguna LGUs and Santa Cruz barangays correctly', () async {
      final service = LocationService();
      final regions = await service.getRegions();
      expect(regions.any((r) => r.code == '040000000'), isTrue);

      final provinces = await service.getProvinces('040000000');
      expect(provinces.any((p) => p.code == '043400000'), isTrue);

      final lagunaCities = await service.getCitiesForProvince('043400000');
      expect(lagunaCities.length, greaterThanOrEqualTo(10));
      expect(lagunaCities.any((c) => c.name.contains('Santa Cruz')), isTrue);
      expect(lagunaCities.any((c) => c.name.contains('Calamba')), isTrue);

      final santaCruzBrgys = await service.getBarangays('043426000');
      expect(santaCruzBrgys.isNotEmpty, isTrue);
      expect(santaCruzBrgys.any((b) => b.name.contains('Poblacion')), isTrue);
    });

    testWidgets('01_philippine_address.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final service = LocationService();
      final lagunaCities = await service.getCitiesForProvince('043400000');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text('Select City / Municipality'),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.jeapPurple.withValues(alpha: 0.08),
                  child: const Row(
                    children: [
                      Icon(Icons.location_city, color: AppTheme.jeapPurple, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Region IV-A (CALABARZON) > Laguna Province',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.jeapPurple,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search 30 Laguna LGUs (e.g. Santa Cruz, Calamba, Biñan)...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: lagunaCities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final city = lagunaCities[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: city.isCity
                              ? AppTheme.jeapPurple.withValues(alpha: 0.1)
                              : Colors.teal.withValues(alpha: 0.1),
                          child: Icon(
                            city.isCity ? Icons.location_city : Icons.nature_people,
                            color: city.isCity ? AppTheme.jeapPurple : Colors.teal,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          city.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'PSGC: ${city.code} • ${city.isCity ? "Component City" : "Municipality"}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../../screenshots/jeap_mobile/01_philippine_address.png'),
      );
    });

    testWidgets('02_barangay_selection.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final service = LocationService();
      final brgys = await service.getBarangays('043426000');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text('Select Barangay'),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.teal.withValues(alpha: 0.08),
                  child: const Row(
                    children: [
                      Icon(Icons.pin_drop, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Laguna > Santa Cruz (Capital) [Postal: 4009]',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Santa Cruz Barangays (Poblacion, Gatid, Bubukal)...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: brgys.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final b = brgys[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.withValues(alpha: 0.15),
                          child: const Icon(Icons.holiday_village_outlined,
                              color: Colors.amber, size: 18),
                        ),
                        title: Text(
                          b.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Barangay Code: ${b.code}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../../screenshots/jeap_mobile/02_barangay_selection.png'),
      );
    });
  });


  group('Priority 2 - Dedicated Logistics Mobile Role & Scanner', () {
    testWidgets('03_logistics_dashboard.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const LogisticsDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(LogisticsDashboardScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/03_logistics_dashboard.png'),
      );
    });

    testWidgets('04_logistics_scanner.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const LogisticsScannerScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(LogisticsScannerScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/04_logistics_scanner.png'),
      );
    });

    testWidgets('05_scan_result.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const demo = LogisticsParcel(
        trackingNumber: 'JP-00000104',
        orderNumber: 'ORD-2026-104',
        status: 'packed',
        recipientName: 'Maria Santos',
        recipientPhone: '0917-555-0199',
        destinationAddress: '124 Rizal St, Brgy. Poblacion, Santa Cruz, Laguna 4009',
        originHub: 'JEAP Central Warehouse - Laguna',
        itemsCount: 3,
        totalAmount: 2150.00,
        paymentMethod: 'Cash on Delivery (COD)',
        allowedActions: ['sort', 'dispatch', 'transfer'],
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const ScanResultScreen(
            parcel: demo,
            currentAction: 'received',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ScanResultScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/05_scan_result.png'),
      );
    });
  });

  group('Priority 3 - Rider Fleet, Vehicle & Documents', () {
    testWidgets('06_rider_fleet.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const RiderFleetScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(RiderFleetScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/06_rider_fleet.png'),
      );
    });

    testWidgets('07_vehicle_information.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const RiderVehicleScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(RiderVehicleScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/07_vehicle_information.png'),
      );
    });

    testWidgets('08_rider_documents.png screenshot', (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const RiderDocumentsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(RiderDocumentsScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/08_rider_documents.png'),
      );
    });
  });

  group('Priority 4 - Shopee-Inspired Guest Shopping Experience', () {
    const sampleProduct = Product(
      id: 'p1',
      name: 'Air Purifier with HEPA Filter',
      price: 489.00,
      rating: 4.8,
      reviewCount: 32,
      imageUrl: 'https://jeap.store/images/categories/cat-kitchen.png',
      description: 'Air purifier with high efficiency HEPA filtration for cleaner home air.',
      stock: 15,
      isFeatured: true,
    );

    testWidgets('09_guest_home.png screenshot', (tester) async {
      AuthSession.instance.setGuest(true);
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(BuyerHomeScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/09_guest_home.png'),
      );
    });

    testWidgets('10_guest_product_details.png screenshot', (tester) async {
      AuthSession.instance.setGuest(true);
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const ProductDetailScreen(product: sampleProduct),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProductDetailScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/10_guest_product_details.png'),
      );
    });

    testWidgets('11_guest_cart.png screenshot', (tester) async {
      AuthSession.instance.setGuest(true);
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final guestItems = [
        BuyerCartItem(
          id: 101,
          productId: 'p1',
          variantId: 1,
          productName: 'Air Purifier with HEPA Filter',
          price: 489.00,
          quantity: 1,
          imageUrl: 'https://jeap.store/images/categories/cat-kitchen.png',
          sellerName: 'Laguna Official Store',
          selected: true,
        ),
        BuyerCartItem(
          id: 102,
          productId: 'p2',
          variantId: 2,
          productName: 'Shaork Robot Vacuum Cleaner',
          price: 325.00,
          quantity: 2,
          imageUrl: 'https://jeap.store/images/categories/cat-kitchen.png',
          sellerName: 'JEAP Express Hub',
          selected: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: CartScreen(initialItems: guestItems),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('../../screenshots/jeap_mobile/11_guest_cart.png'),
      );
    });

    testWidgets('12_guest_login_gate.png screenshot', (tester) async {
      AuthSession.instance.setGuest(true);
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final guestItems = [
        BuyerCartItem(
          id: 101,
          productId: 'p1',
          variantId: 1,
          productName: 'Air Purifier with HEPA Filter',
          price: 489.00,
          quantity: 1,
          selected: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: CartScreen(initialItems: guestItems),
        ),
      );
      await tester.pumpAndSettle();

      // Tap PROCEED TO CHECKOUT
      await tester.tap(find.text('PROCEED TO CHECKOUT (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Sign In Required to Checkout'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../screenshots/jeap_mobile/12_guest_login_gate.png'),
      );
    });
  });
}
