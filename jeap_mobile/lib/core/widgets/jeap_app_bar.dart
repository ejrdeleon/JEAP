import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/wishlist_screen.dart';

/// The JEAP wordmark + back chevron + wishlist heart bar that appears
/// identically at the top of every buyer screen.
/// Home has no back chevron (it's the root tab), so [showBack] defaults
/// to true and Home passes false.
class JeapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final bool showWishlist;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onMenuTap;
  final String? title;
  final List<Widget>? actions;

  const JeapAppBar({
    super.key,
    this.showBack = true,
    this.showWishlist = true,
    this.onWishlistTap,
    this.onMenuTap,
    this.title,
    this.actions,
  });

  void _handleOpenDrawer(BuildContext context) {
    if (onMenuTap != null) {
      onMenuTap!();
      return;
    }
    // 1. Check if the nearest Scaffold has a drawer
    final localScaffold = Scaffold.maybeOf(context);
    if (localScaffold != null && localScaffold.hasDrawer) {
      localScaffold.openDrawer();
      return;
    }
    // 2. Walk up ancestor widgets to find any parent Scaffold with a drawer
    bool opened = false;
    context.visitAncestorElements((element) {
      if (element.widget is Scaffold) {
        final state = (element as StatefulElement).state;
        if (state is ScaffoldState && state.hasDrawer) {
          state.openDrawer();
          opened = true;
          return false; // stop traversal
        }
      }
      return true;
    });
    if (!opened && localScaffold != null) {
      localScaffold.openDrawer();
    }
  }

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
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.menu, color: AppTheme.textPrimary, size: 24),
                tooltip: 'Open Menu',
                onPressed: () => _handleOpenDrawer(context),
              ),
            const SizedBox(width: 8),
            Text(
              title ?? 'JEAP',
              style: const TextStyle(
                color: AppTheme.jeapPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (actions != null)
              ...actions!
            else if (showWishlist)
              InkWell(
                onTap: onWishlistTap ??
                    () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WishlistScreen()),
                        ),
                child: const Icon(Icons.favorite_border,
                    color: AppTheme.jeapPurple, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
