import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';

class SellerService {
  final ApiClient _api;

  SellerService({ApiClient? client}) : _api = client ?? const ApiClient();

  Future<List<Order>> fetchSellerOrders({String? status}) async {
    final path = status != null && status.isNotEmpty
        ? '/orders?status=$status'
        : '/orders';
    final res = await _api.get(path);
    final list = (res is Map ? res['orders'] : res) as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> updateOrderStatus({
    required String orderNumber,
    required String status,
    String? notes,
  }) async {
    await _api.post('/seller/orders/$orderNumber/status', {
      'status': status,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<List<Product>> fetchSellerProducts() async {
    final res = await _api.get('/products');
    final list = (res is Map && res.containsKey('data'))
        ? res['data'] as List
        : (res is Map && res.containsKey('products'))
            ? res['products'] as List
            : (res as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
