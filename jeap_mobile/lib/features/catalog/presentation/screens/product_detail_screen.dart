import 'package:jeap_mobile/core/storage/guest_cart_manager.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/storage/wishlist_manager.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;
  String? _selectedSize;
  late int _stock;
  bool _addingToCart = false;

  final List<String> _availableSizes = ['S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    _stock = widget.product.stock;
    if (widget.product.colors.isNotEmpty) {
      _selectedColor = widget.product.colors.first;
      _stock = widget.product.stocksByColor[_selectedColor] ?? widget.product.stock;
    }
    // If it's a clothing item or has variants, default size
    if (widget.product.category?.toLowerCase().contains('cloth') == true ||
        widget.product.category?.toLowerCase().contains('fashion') == true) {
      _selectedSize = 'M';
    }
  }

  int get _effectiveMaxStock => min(20, _stock);

  bool get _canAddToCart {
    final needsColor =
        widget.product.colors.isNotEmpty && _selectedColor == null;
    return !needsColor && _stock > 0 && _quantity >= 1;
  }

  Future<void> _addToCart({bool navigateToCart = false}) async {
    if (AuthSession.instance.isGuest) {
      final p = widget.product;
      final variations = <String, String>{};
      if (_selectedColor != null) variations['Color'] = _selectedColor!;
      if (_selectedSize != null) variations['Size'] = _selectedSize!;

      await GuestCartManager.instance.addItem(
        productId: p.id,
        variantId: p.variantIdsByColor[_selectedColor] ?? p.variantId ?? 1,
        productName: p.name,
        price: p.price,
        quantity: _quantity,
        imageUrl: p.imageUrl,
        variations: variations,
      );

      if (!mounted) return;
      if (navigateToCart) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} added to cart!'),
            backgroundColor: AppTheme.statusGreen,
          ),
        );
      }
      return;
    }
    if (!_canAddToCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required options.')),
      );
      return;
    }
    setState(() => _addingToCart = true);
    final p = widget.product;
    final variations = <String, String>{};
    if (_selectedColor != null) variations['Color'] = _selectedColor!;
    if (_selectedSize != null) variations['Size'] = _selectedSize!;

    try {
      await CartService().addItem(
        variantId: p.variantIdsByColor[_selectedColor] ?? p.variantId ?? 1,
        productId: p.id,
        productName: p.name,
        price: p.price,
        quantity: _quantity,
        imageUrl: p.imageUrl,
        variations: variations,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _addingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add to cart. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _addingToCart = false);

    if (navigateToCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to cart!'),
          backgroundColor: AppTheme.statusGreen,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: WishlistManager.instance,
            builder: (context, _) {
              final isWish = WishlistManager.instance.isWishlisted(p.id);
              return IconButton(
                icon: Icon(
                  isWish ? Icons.favorite : Icons.favorite_border,
                  color: isWish ? Colors.redAccent : AppTheme.textPrimary,
                ),
                tooltip: isWish ? 'Remove from Wishlist' : 'Add to Wishlist',
                onPressed: () {
                  WishlistManager.instance.toggle(p);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isWish
                            ? 'Removed from Wishlist'
                            : 'Added to Wishlist!',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: double.infinity,
                      height: 280,
                      color: AppTheme.inputFill,
                      alignment: Alignment.center,
                      child: JeapNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: 280,
                        fallback: const Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price & compare price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₱${p.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.priceRed,
                                ),
                              ),
                              if (p.compareAtPrice != null &&
                                  p.compareAtPrice! > p.price) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '₱${p.compareAtPrice!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${(((p.compareAtPrice! - p.price) / p.compareAtPrice!) * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Name
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Rating & stock status
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < p.rating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${p.rating} (${p.reviewCount} reviews)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _stock > 0
                                      ? AppTheme.statusGreen.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _stock > 0 ? '$_stock In Stock' : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _stock > 0
                                        ? AppTheme.statusGreen
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          // Color variations
                          if (p.colors.isNotEmpty) ...[
                            const Text(
                              'Color',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: p.colors.map((c) {
                                final isSel = _selectedColor == c;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedColor = c;
                                    _stock = p.stocksByColor[c] ?? p.stock;
                                    _quantity = 1;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppTheme.jeapPurple
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel
                                            ? AppTheme.jeapPurple
                                            : AppTheme.borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      c[0].toUpperCase() + c.substring(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSel
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Size options if applicable
                          if (_selectedSize != null) ...[
                            const Text(
                              'Size',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: _availableSizes.map((s) {
                                final isSel = _selectedSize == s;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSize = s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppTheme.jeapPurple
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel
                                            ? AppTheme.jeapPurple
                                            : AppTheme.borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSel
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Quantity Selector
                          const Text(
                            'Quantity',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: _quantity < _effectiveMaxStock
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Max $_effectiveMaxStock per order',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          // Description
                          if (p.description != null &&
                              p.description!.isNotEmpty) ...[
                            const Text(
                              'Description',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.description!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const Divider(height: 28),
                          ],

                          // Store / Chat Row
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.inputFill,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.buyerRadius),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppTheme.jeapPurple,
                                  child: Icon(Icons.storefront,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.brand ?? 'Official JEAP Merchant',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Text(
                                        'Verified Seller • 100% Authentic',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.chat_outlined,
                                      size: 14),
                                  label: const Text('Chat',
                                      style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.jeapPurple,
                                    side: const BorderSide(
                                        color: AppTheme.jeapPurple),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  onPressed: () {
                                    if (AuthSession.instance.isGuest) {
                                      showGuestActionDialog(
                                        context,
                                        title: 'Sign In Required',
                                        message:
                                            'Please sign in to chat directly with this seller.',
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BuyerChatScreen(
                                          conversation: Conversation(
                                            id: 1,
                                            participantName: p.brand ??
                                                'JEAP Merchant Support',
                                            participantRole: 'seller',
                                            lastMessage:
                                                'Hello, how can I assist with this item?',
                                            lastMessageAt: DateTime.now(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'ADD TO CART',
                      onPressed: _stock > 0 && !_addingToCart
                          ? () => _addToCart()
                          : null,
                      loading: _addingToCart,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'BUY NOW',
                      onPressed: _stock > 0 && !_addingToCart
                          ? () => _addToCart(navigateToCart: true)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.jeapPurple.withValues(alpha: 0.1)
              : AppTheme.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppTheme.jeapPurple : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
