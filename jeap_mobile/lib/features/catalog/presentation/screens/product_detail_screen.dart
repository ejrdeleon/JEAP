import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;
  late int _stock;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    _stock = widget.product.stock;
  }

  bool get _canAddToCart {
    final needsColor =
        widget.product.colors.isNotEmpty && _selectedColor == null;
    return !needsColor && _quantity >= 1;
  }

  Future<void> _addToCart({bool navigateToCart = false}) async {
    if (!_canAddToCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required options.')),
      );
      return;
    }
    setState(() => _addingToCart = true);
    final p = widget.product;
    try {
      await CartService().addItem(
        productId: p.id,
        productName: p.name,
        price: p.price,
        quantity: _quantity,
        imageUrl: p.imageUrl,
        variations: {if (_selectedColor != null) 'Color': _selectedColor!},
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
      appBar: const JeapAppBar(),
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
                      height: 260,
                      color: AppTheme.inputFill,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined,
                          size: 64, color: AppTheme.textSecondary),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name & price
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            '₱${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.priceRed),
                          ),
                          const SizedBox(height: 8),
                          // Rating
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
                                      )),
                              const SizedBox(width: 6),
                              Text('${p.rating} (${p.reviewCount} reviews)',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _stock > 0
                                ? '$_stock items available'
                                : 'Out of stock',
                            style: TextStyle(
                                fontSize: 12,
                                color: _stock > 0
                                    ? AppTheme.statusGreen
                                    : Colors.red),
                          ),
                          const Divider(height: 24),
                          // Description
                          if (p.description != null) ...[
                            const Text('Description',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(p.description!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.5)),
                            const Divider(height: 24),
                          ],
                          // Color variations
                          if (p.colors.isNotEmpty) ...[
                            const Text('Color',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: p.colors
                                  .map((c) => GestureDetector(
                                        onTap: () =>
                                            setState(() => _selectedColor = c),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _selectedColor == c
                                                ? AppTheme.jeapPurple
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _selectedColor == c
                                                  ? AppTheme.jeapPurple
                                                  : AppTheme.borderColor,
                                            ),
                                          ),
                                          child: Text(
                                            c[0].toUpperCase() + c.substring(1),
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: _selectedColor == c
                                                    ? Colors.white
                                                    : AppTheme.textPrimary,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const Divider(height: 24),
                          ],
                          // Quantity
                          const Text('Quantity',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
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
                              Text('$_quantity',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: _quantity < _stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text('/ $_stock available',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.jeapPurple.withValues(alpha: 0.1)
              : AppTheme.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon,
            size: 18,
            color:
                onTap != null ? AppTheme.jeapPurple : AppTheme.textSecondary),
      ),
    );
  }
}
