import 'package:flutter/foundation.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';

export 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';

class CartService {
  CartService({ApiClient? api}) : _api = api ?? const ApiClient();
  final ApiClient _api;

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<List<BuyerCartItem>> fetchCart() async {
    final res = await _api.get('/cart');
    final items = (res is Map ? res['items'] : res) as List? ?? [];
    return items
        .whereType<Map>()
        .map((e) => BuyerCartItem.fromApi(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addItem({
    required int variantId,
    required String productId,
    required String productName,
    required double price,
    int quantity = 1,
    Map<String, String> variations = const {},
    String? imageUrl,
  }) async {
    if (quantity < 1) throw ArgumentError('Quantity must be at least 1.');
    await _api.post('/cart', {
      'product_variant_id': variantId,
      'quantity': quantity,
    });
    revision.value++;
  }

  Future<void> updateItem(int itemId, int quantity) async {
    if (quantity < 1) throw ArgumentError('Quantity must be at least 1.');
    await _api.put('/cart/$itemId', {'quantity': quantity});
    revision.value++;
  }

  Future<void> removeItem(int itemId) async {
    await _api.delete('/cart/$itemId');
    revision.value++;
  }

  Future<void> clear() async {
    final items = await fetchCart();
    for (final item in items) {
      await _api.delete('/cart/${item.id}');
    }
    revision.value++;
  }
}
