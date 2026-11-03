import 'package:flutter/foundation.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';

class WishlistManager extends ChangeNotifier {
  WishlistManager._();
  static final WishlistManager instance = WishlistManager._();

  final ApiClient _api = const ApiClient();
  final List<Product> _items = [];
  bool _initialized = false;

  List<Product> get items => List.unmodifiable(_items);

  bool isWishlisted(String productId) =>
      _items.any((p) => p.id == productId);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    if (!AuthSession.instance.isAuthenticated) {
      _items.clear();
      notifyListeners();
      return;
    }
    try {
      final res = await _api.get('/wishlist');
      final list = res is Map ? (res['data'] as List? ?? []) : const [];
      _items
        ..clear()
        ..addAll(list
            .whereType<Map>()
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e))));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggle(Product product) async {
    if (!AuthSession.instance.isAuthenticated) return;
    final already = isWishlisted(product.id);
    try {
      if (already) {
        await _api.delete('/wishlist/${product.id}');
        _items.removeWhere((p) => p.id == product.id);
      } else {
        await _api.post('/wishlist/${product.id}', {});
        _items.add(product);
      }
      notifyListeners();
    } catch (_) {
      await refresh();
    }
  }

  Future<void> remove(String productId) async {
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      await _api.delete('/wishlist/$productId');
      _items.removeWhere((p) => p.id == productId);
      notifyListeners();
    } catch (_) {
      await refresh();
    }
  }
}
