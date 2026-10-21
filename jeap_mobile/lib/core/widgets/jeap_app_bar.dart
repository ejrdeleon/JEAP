import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';

/// The JEAP wordmark + back chevron + wishlist heart bar that appears
/// at the top of buyer screens.
class JeapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final bool showWishlist;
  final VoidCallback? onWishlistTap;

  const JeapAppBar({
    super.key,
    this.showBack = true,
    this.showWishlist = true,
    this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showBack)
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.chevron_left,
                      color: AppTheme.textPrimary, size: 26),
                ),
              ),
            const JeapLogo(height: 26),
            const Spacer(),
            if (showWishlist)
              InkWell(
                onTap: onWishlistTap,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.favorite_border,
                      color: AppTheme.jeapPurple, size: 22),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
