import 'package:jeap_mobile/core/storage/guest_cart_manager.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:jeap_mobile/features/checkout/presentation/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final List<BuyerCartItem>? initialItems;
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onSelectTab;

  const CartScreen({
    super.key,
    this.initialItems,
    this.onOpenDrawer,
    this.onSelectTab,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  List<BuyerCartItem> _items = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _items = List.from(widget.initialItems!);
      _loading = false;
    } else {
      _loadCart();
    }
    CartService.revision.addListener(_loadCart);
    GuestCartManager.instance.addListener(_loadCart);
  }

  @override
  void dispose() {
    CartService.revision.removeListener(_loadCart);
    GuestCartManager.instance.removeListener(_loadCart);
    super.dispose();
  }

  Future<void> _loadCart() async {
    if (widget.initialItems != null && _items.isNotEmpty && CartService.revision.value == 0) {
      return;
    }
    if (AuthSession.instance.isGuest) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = List.from(GuestCartManager.instance.items);
        _errorMessage = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final items = await _cartService.fetchCart();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not load your cart. Check your internet connection.';
      });
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

  void _toggleStore(String sellerName, bool? v) {
    setState(() {
      for (final item in _items) {
        if ((item.sellerName ?? 'JEAP Official Store') == sellerName) {
          item.selected = v ?? false;
        }
      }
    });
  }

  Future<void> _removeItem(int id) async {
    final removed = _items.firstWhere((i) => i.id == id);
    if (AuthSession.instance.isGuest) {
      await GuestCartManager.instance.removeItem(id);
      if (mounted) {
        setState(() => _items = List.from(GuestCartManager.instance.items));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${removed.productName} removed from cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    setState(() => _items.removeWhere((i) => i.id == id));
    try {
      await _cartService.removeItem(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${removed.productName} removed from cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) _loadCart();
    }
  }

  Future<void> _updateQty(BuyerCartItem item, int delta) async {
    final newQty = item.quantity + delta;
    if (newQty < 1) return;
    if (AuthSession.instance.isGuest) {
      await GuestCartManager.instance.updateQuantity(item.id, newQty);
      if (mounted) {
        setState(() => _items = List.from(GuestCartManager.instance.items));
      }
      return;
    }
    setState(() => item.quantity = newQty);
    try {
      await _cartService.updateItem(item.id, newQty);
    } catch (_) {
      if (mounted) _loadCart();
    }
  }

  Map<String, List<BuyerCartItem>> get _groupedItems {
    final map = <String, List<BuyerCartItem>>{};
    for (final item in _items) {
      final store = item.sellerName?.trim().isNotEmpty == true
          ? item.sellerName!.trim()
          : 'JEAP Official Store';
      map.putIfAbsent(store, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (AuthSession.instance.isGuest && _items.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        drawer: BuyerDrawer(currentTabIndex: 2, onSelectTab: widget.onSelectTab),
        appBar: JeapAppBar(showBack: false, showWishlist: false, onMenuTap: widget.onOpenDrawer),
        body: const SafeArea(
          child: GuestPromptView(
            title: 'Your Cart is Waiting',
            message:
                'Sign in to your JEAP account to view saved cart items, apply voucher codes, and checkout securely.',
            icon: Icons.shopping_cart_outlined,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: BuyerDrawer(currentTabIndex: 2, onSelectTab: widget.onSelectTab),
      appBar: JeapAppBar(showBack: false, showWishlist: false, onMenuTap: widget.onOpenDrawer),
      body: SafeArea(
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.jeapPurple))
            : _errorMessage != null && _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_outlined,
                              size: 64, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadCart,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.jeapPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadCart,
                        color: AppTheme.jeapPurple,
                        child: ListView(
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.28),
                            _buildEmpty(),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCart,
                        color: AppTheme.jeapPurple,
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
                            // Select all row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _allSelected,
                                    activeColor: AppTheme.jeapPurple,
                                    onChanged: _toggleAll,
                                  ),
                                  const Text('Select All',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Grouped List by Store
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                children: _groupedItems.entries.map((entry) {
                                  final storeName = entry.key;
                                  final storeItems = entry.value;
                                  final storeSelected =
                                      storeItems.every((i) => i.selected);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.buyerRadius),
                                      border: Border.all(
                                          color: AppTheme.borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Store Header
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: storeSelected,
                                                activeColor: AppTheme.jeapPurple,
                                                onChanged: (v) =>
                                                    _toggleStore(storeName, v),
                                              ),
                                              const Icon(Icons.storefront,
                                                  size: 18,
                                                  color: AppTheme.jeapPurple),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  storeName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        // Store Items
                                        ...storeItems.map(
                                          (item) => _CartItemRow(
                                            item: item,
                                            onToggle: (v) => setState(() =>
                                                item.selected = v ?? false),
                                            onRemove: () =>
                                                _removeItem(item.id),
                                            onQtyChange: (delta) =>
                                                _updateQty(item, delta),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.inputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Discover great deals and add items to your cart.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
              Expanded(
                child: Text('Subtotal (${_selectedItems.length} items)',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${_selectedSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 17,
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
                : () {
                    if (AuthSession.instance.isGuest) {
                      _showGuestCheckoutGate();
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                            items: _selectedItems, subtotal: _selectedSubtotal),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  void _showGuestCheckoutGate() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppTheme.jeapPurple,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sign In Required to Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are currently browsing as a guest. Please sign in or create an account to complete your purchase, apply delivery addresses, and track orders in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.jeapPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'SIGN IN TO JEAP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.jeapPurple,
                  side: const BorderSide(color: AppTheme.jeapPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'CREATE NEW ACCOUNT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Continue Browsing',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final BuyerCartItem item;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onRemove;
  final void Function(int delta) onQtyChange;

  const _CartItemRow({
    required this.item,
    required this.onToggle,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            activeColor: AppTheme.jeapPurple,
            onChanged: onToggle,
          ),
          // Product Thumbnail
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: JeapNetworkImage(
              imageUrl: item.imageUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '₱${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.priceRed,
                            fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        foregroundColor: Colors.redAccent),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
