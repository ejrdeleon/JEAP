import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:jeap_mobile/features/checkout/presentation/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  List<BuyerCartItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
    CartService.revision.addListener(_loadCart);
  }

  @override
  void dispose() {
    CartService.revision.removeListener(_loadCart);
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final items = await _cartService.fetchCart();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _allSelected => _items.isNotEmpty && _items.every((i) => i.selected);

  double get _selectedSubtotal =>
      _items.where((i) => i.selected).fold(0, (sum, i) => sum + i.subtotal);

  List<BuyerCartItem> get _selectedItems =>
      _items.where((i) => i.selected).toList();

  void _toggleAll(bool? v) {
    setState(() {
      for (final item in _items) {
        item.selected = v ?? false;
      }
    });
  }

  Future<void> _removeItem(int id) async {
    setState(() => _items.removeWhere((i) => i.id == id));
    try {
      await _cartService.removeItem(id);
    } catch (_) {
      if (mounted) _loadCart(); // roll back the optimistic removal
    }
  }

  Future<void> _updateQty(BuyerCartItem item, int delta) async {
    final newQty = item.quantity + delta;
    if (newQty < 1) return;
    setState(() => item.quantity = newQty);
    try {
      await _cartService.updateItem(item.id, newQty);
    } catch (_) {
      if (mounted) _loadCart(); // roll back the optimistic change
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(showBack: false, showWishlist: false),
      body: SafeArea(
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadCart,
                    child: ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3),
                        _buildEmpty(),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCart,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            children: [
                              const Text('My Cart',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text('${_items.length} item(s)',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        // Select all
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _allSelected,
                                activeColor: AppTheme.jeapPurple,
                                onChanged: _toggleAll,
                              ),
                              const Text('Select All',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _items.length,
                            itemBuilder: (_, i) => _CartItemCard(
                              item: _items[i],
                              onToggle: (v) => setState(
                                  () => _items[i].selected = v ?? false),
                              onRemove: () => _removeItem(_items[i].id),
                              onQtyChange: (delta) =>
                                  _updateQty(_items[i], delta),
                            ),
                          ),
                        ),
                        _buildSummary(context),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72, color: AppTheme.borderColor),
          SizedBox(height: 16),
          Text('Your cart is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Add items to get started.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${_selectedItems.length} selected)',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              Text(
                '₱${_selectedSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.priceRed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'PROCEED TO CHECKOUT (${_selectedItems.length})',
            onPressed: _selectedItems.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                            items: _selectedItems, subtotal: _selectedSubtotal),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final BuyerCartItem item;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onRemove;
  final void Function(int delta) onQtyChange;

  const _CartItemCard({
    required this.item,
    required this.onToggle,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            activeColor: AppTheme.jeapPurple,
            onChanged: onToggle,
          ),
          // Image placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (item.variations.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variations.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(', '),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
                if (item.sellerName != null) ...[
                  const SizedBox(height: 2),
                  Text(item.sellerName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.priceRed,
                          fontSize: 14),
                    ),
                    Row(
                      children: [
                        _SmallQtyBtn(
                            icon: Icons.remove,
                            onTap: item.quantity > 1
                                ? () => onQtyChange(-1)
                                : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        _SmallQtyBtn(
                            icon: Icons.add, onTap: () => onQtyChange(1)),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        foregroundColor: Colors.red),
                    child: const Text('Remove', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SmallQtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon,
            size: 14,
            color:
                onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary),
      ),
    );
  }
}
