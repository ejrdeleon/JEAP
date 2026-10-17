import 'package:flutter/foundation.dart';
import 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';

export 'package:jeap_mobile/features/cart/models/buyer_cart_item.dart';

final _cart = <BuyerCartItem>[];
int _nextId = 1;

/// TEMPORARY in-memory cart. Method signatures are async so swapping in
/// ApiClient calls later changes nothing for the screens.
class CartService {
  /// Bumped on add/remove/clear. CartScreen listens to this because the
  /// tab lives in an IndexedStack and would otherwise never refresh.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<List<BuyerCartItem>> fetchCart() async => List.unmodifiable(_cart);

  Future<void> addItem({
    required String productId,
    required String productName,
    required double price,
    int quantity = 1,
    Map<String, String> variations = const {},
    String? imageUrl,
  }) async {
    if (quantity < 1) throw ArgumentError('Quantity must be at least 1.');
    final idx = _cart.indexWhere(
        (i) => i.productId == productId && _mapsEqual(i.variations, variations));
    if (idx != -1) {
      _cart[idx].quantity += quantity;
    } else {
      _cart.add(BuyerCartItem(
        id: _nextId++,
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        variations: variations,
      ));
    }
    revision.value++;
  }

  Future<void> updateItem(int itemId, int quantity) async {
    if (quantity < 1) throw ArgumentError('Quantity must be at least 1.');
    final idx = _cart.indexWhere((i) => i.id == itemId);
    if (idx != -1) _cart[idx].quantity = quantity;
  }

  Future<void> removeItem(int itemId) async {
    _cart.removeWhere((i) => i.id == itemId);
    revision.value++;
  }

  Future<void> clear() async {
    _cart.clear();
    revision.value++;
  }
}

bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (a[k] != b[k]) return false;
  }
  return true;
}
