import 'package:flutter/foundation.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';

// TEMPORARY in-memory store. The two seeded orders were moved here from
// OrdersScreen so every screen reads one source of truth.
final _orders = <Order>[
  Order(
    id: '1',
    orderNumber: 'JEAP-20240001',
    items: [
      OrderItem(
          productId: 'p1',
          productName: 'MacBook Air M2',
          price: 999.00,
          quantity: 1),
    ],
    status: OrderStatus.sellerPreparing,
    subtotal: 999.00,
    discount: 0,
    deliveryFee: 60,
    total: 1059.00,
    deliveryAddress: '123 Main St, Quezon City',
    paymentMethod: 'Cash on Delivery',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Order(
    id: '2',
    orderNumber: 'JEAP-20240002',
    items: [
      OrderItem(
          productId: 'p2',
          productName: 'Sony WH-1000XM5',
          price: 349.00,
          quantity: 2,
          variations: {'Color': 'Black'}),
    ],
    status: OrderStatus.delivered, // delivered so Confirm Received is testable
    subtotal: 698.00,
    discount: 69.80,
    deliveryFee: 60,
    total: 688.20,
    deliveryAddress: '123 Main St, Quezon City',
    paymentMethod: 'GCash',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];
int _orderSeq = 3;

class OrderService {
  /// Bumped whenever an order is created or changes status.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<List<Order>> fetchOrders({OrderStatus? status}) async {
    final list = status == null
        ? List<Order>.of(_orders)
        : _orders.where((o) => o.status == status).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Order?> fetchOrder(String orderNumber) async {
    for (final o in _orders) {
      if (o.orderNumber == orderNumber) return o;
    }
    return null;
  }

  Future<Order> placeOrder({
    required List<OrderItem> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? voucherCode,
    double discount = 0,
    double deliveryFee = 60,
  }) async {
    if (items.isEmpty) {
      throw const ApiException(message: 'Your order has no items.');
    }
    if (items.any((i) => i.quantity < 1)) {
      throw const ApiException(message: 'Invalid item quantity.');
    }
    if (paymentMethod.isEmpty) {
      throw const ApiException(message: 'Select a payment method.');
    }
    // NOTE: totals are computed client-side only because the backend does
    // not exist yet. The real API must recompute price/stock/discount.
    final subtotal = items.fold(0.0, (s, i) => s + i.subtotal);
    final order = Order(
      id: _orderSeq.toString(),
      orderNumber: 'JEAP-${_orderSeq.toString().padLeft(5, '0')}',
      items: items,
      status: OrderStatus.toPay,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: subtotal - discount + deliveryFee,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    _orderSeq++;
    revision.value++;
    return order;
  }

  Future<void> confirmReceived(String orderNumber) async {
    final idx = _orders.indexWhere((o) => o.orderNumber == orderNumber);
    if (idx == -1) {
      throw const ApiException(message: 'Order not found.');
    }
    final o = _orders[idx];
    if (o.status != OrderStatus.delivered) {
      throw const ApiException(
          message: 'Only delivered orders can be confirmed.');
    }
    _orders[idx] = Order(
      id: o.id,
      orderNumber: o.orderNumber,
      items: o.items,
      status: OrderStatus.completed,
      subtotal: o.subtotal,
      discount: o.discount,
      deliveryFee: o.deliveryFee,
      total: o.total,
      deliveryAddress: o.deliveryAddress,
      paymentMethod: o.paymentMethod,
      voucherCode: o.voucherCode,
      createdAt: o.createdAt,
      completedAt: DateTime.now(),
    );
    revision.value++;
  }

  Future<void> submitRating({
    required String orderNumber,
    required String productId,
    required double rating,
    required String review,
  }) async {
    final order = await fetchOrder(orderNumber);
    if (order == null) {
      throw const ApiException(message: 'Order not found.');
    }
    if (order.status != OrderStatus.completed) {
      throw const ApiException(message: 'Only completed orders can be rated.');
    }
    for (final item in order.items) {
      if (item.productId == productId) {
        item.rating = rating;
        item.review = review;
      }
    }
  }
}
