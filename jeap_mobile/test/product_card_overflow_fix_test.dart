import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';

void main() {
  group('ProductCard 2-line title overflow verification', () {
    final testProducts = [
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
      const Product(
        id: 'p5',
        name: 'Marshall Standmore Speaker Black',
        price: 349.00,
        rating: 0.0,
        reviewCount: 0,
      ),
      const Product(
        id: 'p6',
        name: 'Gaming Console Bundle',
        price: 499.00,
        rating: 0.0,
        reviewCount: 0,
      ),
    ];

    testWidgets('renders grid with 2-line titles without any RenderFlex bottom overflow',
        (tester) async {
      // Test across multiple device aspect ratios and widths
      final phoneSizes = [
        const Size(360, 780),
        const Size(375, 812),
        const Size(390, 844),
        const Size(412, 915),
        const Size(504, 1024),
      ];

      for (final size in phoneSizes) {
        tester.view.physicalSize = Size(size.width * 2.5, size.height * 2.5);
        tester.view.devicePixelRatio = 2.5;

        final width = size.width;
        final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
        final childAspectRatio = width < 360 ? 0.56 : (width < 600 ? 0.58 : 0.65);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: testProducts.length,
                itemBuilder: (_, i) => ProductCard(product: testProducts[i]),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Shaork Robot Vacuum'), findsOneWidget);
        expect(find.text('Durotan Manual Espresso Machine'), findsOneWidget);
        expect(find.text('Sona QLED Ultra HD 4K Smart TV'), findsOneWidget);
        expect(find.text('iPad mini 2023 Wi-Fi 256GB'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('renders safely even with large text scaler and bounded constraint',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.2),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: testProducts.length,
              itemBuilder: (_, i) => ProductCard(product: testProducts[i]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely in unbounded height context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 180,
                child: ProductCard(product: testProducts[1]),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Durotan Manual Espresso Machine'), findsOneWidget);
    });
  });
}
