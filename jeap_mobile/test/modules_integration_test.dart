import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/storage/wishlist_manager.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/wishlist_screen.dart';

void main() {
  group('WishlistManager Unit Tests', () {
    test('Wishlist toggles and removes items in memory', () async {
      final manager = WishlistManager.instance;
      const product = Product(
        id: '99',
        name: 'Wireless Bluetooth Earbuds',
        price: 899.00,
        stock: 15,
      );

      expect(manager.isWishlisted('99'), isFalse);

      await manager.toggle(product);
      expect(manager.isWishlisted('99'), isTrue);
      expect(manager.items.any((p) => p.id == '99'), isTrue);

      await manager.toggle(product);
      expect(manager.isWishlisted('99'), isFalse);

      await manager.toggle(product);
      expect(manager.isWishlisted('99'), isTrue);

      await manager.remove('99');
      expect(manager.isWishlisted('99'), isFalse);
    });
  });

  group('DeliveryTask Model & Payout Calculation Tests', () {
    test('Calculates pickup and delivery payouts correctly', () {
      final pickupJson = {
        'id': 'task-101',
        'tracking_number': 'TRK-PICKUP-01',
        'type': 'pickup',
        'status': 'pending',
        'recipient_name': 'Supplier Hub',
      };
      final pickupTask = DeliveryTask.fromApi(pickupJson);
      expect(pickupTask.isPickup, isTrue);
      expect(pickupTask.payout, 30.0);
      expect(pickupTask.attemptNumber, 1);

      final deliveryJson = {
        'id': 'task-102',
        'tracking_number': 'TRK-DELIVERY-01',
        'type': 'delivery',
        'status': 'out_for_delivery',
        'recipient_name': 'Buyer Juan',
        'cod_amount': 750.50,
        'attempt_number': 2,
      };
      final deliveryTask = DeliveryTask.fromApi(deliveryJson);
      expect(deliveryTask.isPickup, isFalse);
      expect(deliveryTask.payout, 50.0);
      expect(deliveryTask.codAmount, 750.50);
      expect(deliveryTask.attemptNumber, 2);
    });
  });

  group('Courier Container Seal Regex Validation', () {
    test('Validates BH- plus 7 digits format strictly', () {
      final regex = RegExp(r'^BH-\d{7}$');

      expect(regex.hasMatch('BH-1049281'), isTrue);
      expect(regex.hasMatch('BH-0000001'), isTrue);
      expect(regex.hasMatch('BH-9999999'), isTrue);

      // Invalid formats
      expect(regex.hasMatch('BH-123456'), isFalse); // only 6 digits
      expect(regex.hasMatch('BH-12345678'), isFalse); // 8 digits
      expect(regex.hasMatch('AB-1049281'), isFalse); // wrong prefix
      expect(regex.hasMatch('BH1049281'), isFalse); // missing dash
      expect(regex.hasMatch('BH-104928A'), isFalse); // contains letter
    });
  });

  group('Order Status & COD Classification Tests', () {
    test('Maps statuses properly from string', () {
      expect(OrderStatusLabel.fromString('to_pay'), OrderStatus.toPay);
      expect(OrderStatusLabel.fromString('preparing'), OrderStatus.sellerPreparing);
      expect(OrderStatusLabel.fromString('ready_for_pickup'), OrderStatus.riderPickup);
      expect(OrderStatusLabel.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatusLabel.fromString('cancelled'), OrderStatus.cancelled);
      expect(OrderStatusLabel.fromString('return_refund'), OrderStatus.returnRefund);
    });
  });

  group('WishlistScreen Widget Tests', () {
    testWidgets('Renders empty state when wishlist has no items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WishlistScreen(),
        ),
      );

      expect(find.text('Your Wishlist is Empty'), findsOneWidget);
      expect(find.text('EXPLORE PRODUCTS'), findsOneWidget);
    });
  });
}
