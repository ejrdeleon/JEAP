import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';

/// The JEAP wordmark + back chevron + wishlist heart bar that appears
/// identically at the top of every buyer screen.
/// Home has no back chevron (it's the root tab), so [showBack] defaults
/// to true and Home passes false.
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
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.chevron_left,
                      color: AppTheme.textPrimary, size: 26),
                ),
              )
            else
              const Icon(Icons.menu, color: AppTheme.textPrimary, size: 22),
            const SizedBox(width: 4),
            const Text(
              'JEAP',
              style: TextStyle(
                color: AppTheme.jeapPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (showWishlist)
              InkWell(
                onTap: onWishlistTap,
                child: const Icon(Icons.favorite_border,
                    color: AppTheme.jeapPurple, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
