import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jeap_mobile/core/models/product.dart';

class WishlistManager extends ChangeNotifier {
  WishlistManager._();
  static final WishlistManager instance = WishlistManager._();

  static const _storageKey = 'jeap_wishlist_items_v1';
  static const _storage = FlutterSecureStorage();
  final List<Product> _items = [];
  bool _initialized = false;

  List<Product> get items => List.unmodifiable(_items);

  bool isWishlisted(String productId) =>
      _items.any((p) => p.id == productId);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _items.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _items.add(Product.fromJson(item));
          }
        }
      }
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggle(Product product) async {
    final idx = _items.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _items.removeAt(idx);
    } else {
      _items.add(product);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String productId) async {
    _items.removeWhere((p) => p.id == productId);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final data = _items.map((p) => {
        'id': p.id,
        'name': p.name,
        'price': p.price,
        'compare_at_price': p.compareAtPrice,
        'rating': p.rating,
        'review_count': p.reviewCount,
        'image_url': p.imageUrl,
        'description': p.description,
        'stock': p.stock,
      }).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(data));
    } catch (_) {}
  }
}
