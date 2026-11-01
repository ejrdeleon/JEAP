import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/storage/wishlist_manager.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';

/// The vertical product card seen in "Best Sellers" on Home — image
/// placeholder, NEW badge, name, rating, price, wishlist heart.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final imageWidget = Container(
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: JeapNetworkImage(
            imageUrl: product.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fallback: const Icon(
              Icons.image_outlined,
              color: AppTheme.textSecondary,
              size: 28,
            ),
          ),
        );

        final imageStack = Stack(
          fit: hasBoundedHeight ? StackFit.expand : StackFit.loose,
          children: [
            hasBoundedHeight
                ? imageWidget
                : AspectRatio(
                    aspectRatio: 1.30,
                    child: imageWidget,
                  ),
            if (product.isNew)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.jeapPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!product.inStock)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: hasBoundedHeight
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (hasBoundedHeight)
                  Expanded(child: imageStack)
                else
                  imageStack,
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '${product.rating} (${product.reviewCount})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.priceRed,
                            fontSize: 13),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: WishlistManager.instance,
                      builder: (context, _) {
                        final wishlisted =
                            WishlistManager.instance.isWishlisted(product.id);
                        return InkWell(
                          onTap: () => WishlistManager.instance.toggle(product),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              wishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 17,
                              color: wishlisted
                                  ? Colors.redAccent
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
