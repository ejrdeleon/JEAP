import 'package:flutter/foundation.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';

export 'package:jeap_mobile/features/orders/models/order.dart';

class OrderService {
  OrderService({ApiClient? api}) : _api = api ?? const ApiClient();
  final ApiClient _api;

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<List<Order>> fetchOrders({OrderStatus? status}) async {
    final path =
        status != null ? '/orders?status=${_statusParam(status)}' : '/orders';
    final res = await _api.get(path);
    final list = (res is Map ? res['orders'] : res) as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Order?> fetchOrder(String orderNumber) async {
    try {
      final res = await _api.get('/orders/$orderNumber');
      final data = res is Map ? res['order'] ?? res : res;
      return Order.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Order> placeOrder({
    required int addressId,
    required List<int> cartItemIds,
    String paymentMethod = 'cod',
    String? voucherCode,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'address_id': addressId,
      'payment_method': paymentMethod,
      'cart_item_ids': cartItemIds,
      if (voucherCode != null && voucherCode.isNotEmpty)
        'voucher_code': voucherCode,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final res = await _api.post('/orders', body);
    final orders = (res is Map ? res['orders'] : null) as List?;
    if (orders == null || orders.isEmpty) {
      throw const ApiException(message: 'No orders returned from server.');
    }
    revision.value++;
    return Order.fromJson(Map<String, dynamic>.from(orders.first as Map));
  }

  Future<double> validateVoucher({
    required String code,
    required double subtotal,
  }) async {
    final response = await _api.post('/vouchers/validate', {
      'code': code,
      'subtotal': subtotal,
    });
    if (response is! Map || response['discount'] is! num) {
      throw const ApiException(
          message: 'Voucher service returned an invalid response.');
    }
    return (response['discount'] as num).toDouble();
  }

  Future<void> confirmReceived(String orderNumber) async {
    await _api.post('/orders/$orderNumber/confirm', {});
    revision.value++;
  }

  Future<void> cancelOrder(String orderNumber, String reason) async {
    await _api.post('/orders/$orderNumber/cancel', {'reason': reason});
    revision.value++;
  }

  Future<void> submitRating({
    required String orderNumber,
    required String productId,
    required double rating,
    required String review,
  }) async {
    await _api.post('/orders/$orderNumber/rate', {
      'product_id': int.tryParse(productId) ?? productId,
      'rating': rating,
      'review': review,
    });
  }

  static String _statusParam(OrderStatus status) {
    return switch (status) {
      OrderStatus.toPay => 'PLACED',
      OrderStatus.toShip => 'CONFIRMED',
      OrderStatus.sellerPreparing => 'PREPARING',
      OrderStatus.riderPickup => 'PICKED_UP',
      OrderStatus.sortingCenter => 'AT_SORTING_CENTER',
      OrderStatus.assignedRider => 'ASSIGNED_TO_RIDER',
      OrderStatus.outForDelivery => 'OUT_FOR_DELIVERY',
      OrderStatus.delivered => 'DELIVERED',
      OrderStatus.completed => 'COMPLETED',
      OrderStatus.cancelled => 'CANCELLED',
      OrderStatus.returnRefund => 'RETURNED',
    };
  }
}
