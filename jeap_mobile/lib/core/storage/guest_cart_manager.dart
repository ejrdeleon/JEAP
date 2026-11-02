import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';

class GuestCartManager extends ChangeNotifier {
  static final GuestCartManager instance = GuestCartManager._();
  GuestCartManager._() {
    _loadFromStorage();
  }

  static const _storageKey = 'jeap_guest_cart_items_v1';
  static const _storage = FlutterSecureStorage();
  final List<BuyerCartItem> _items = [];

  List<BuyerCartItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (sum, it) => sum + it.quantity);

  double get subtotal => _items
      .where((it) => it.selected)
      .fold(0.0, (sum, it) => sum + it.subtotal);

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _items.clear();
        for (final entry in list) {
          _items.add(BuyerCartItem.fromJson(Map<String, dynamic>.from(entry as Map)));
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final data = _items.map((it) => {
        'id': it.id,
        'product_id': it.productId,
        'variant_id': it.variantId,
        'product_name': it.productName,
        'price': it.price,
        'quantity': it.quantity,
        'image_url': it.imageUrl,
        'variations': it.variations,
        'seller_name': it.sellerName,
        'selected': it.selected,
      }).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(data));
    } catch (_) {}
  }

  Future<void> addItem({
    required String productId,
    required String productName,
    required double price,
    int? variantId,
    int quantity = 1,
    String? imageUrl,
    Map<String, String> variations = const {},
    String? sellerName,
  }) async {
    final existingIdx = _items.indexWhere(
      (it) => it.productId == productId && it.variantId == variantId,
    );

    if (existingIdx != -1) {
      _items[existingIdx].quantity += quantity;
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch ~/ 1000 + _items.length;
      _items.add(
        BuyerCartItem(
          id: newId,
          productId: productId,
          variantId: variantId,
          productName: productName,
          price: price,
          quantity: quantity,
          imageUrl: imageUrl,
          variations: variations,
          sellerName: sellerName,
          selected: true,
        ),
      );
    }

    notifyListeners();
    await _saveToStorage();
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    final idx = _items.indexWhere((it) => it.id == itemId);
    if (idx != -1) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = quantity;
      }
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> removeItem(int itemId) async {
    _items.removeWhere((it) => it.id == itemId);
    notifyListeners();
    await _saveToStorage();
  }

  void toggleSelected(int itemId) {
    final idx = _items.indexWhere((it) => it.id == itemId);
    if (idx != -1) {
      _items[idx].selected = !_items[idx].selected;
      notifyListeners();
      _saveToStorage();
    }
  }

  void toggleAll(bool selected) {
    for (final it in _items) {
      it.selected = selected;
    }
    notifyListeners();
    _saveToStorage();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }

  /// Merges all local guest cart items into the authenticated user's cart.
  Future<void> mergeIntoAccount(CartService cartService) async {
    if (_items.isEmpty) return;

    final copy = List<BuyerCartItem>.from(_items);
    for (final it in copy) {
      try {
        final vId = it.variantId ?? int.tryParse(it.productId) ?? 1;
        await cartService.addItem(
          variantId: vId,
          productId: it.productId,
          productName: it.productName,
          price: it.price,
          quantity: it.quantity,
          imageUrl: it.imageUrl,
          variations: it.variations,
        );
      } catch (_) {}
    }

    await clear();
  }
}
