import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/utils/category_icons.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/data/mock_data.dart';
import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/category_products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onSelectTab;

  const CategoriesScreen({
    super.key,
    this.onOpenDrawer,
    this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    const cats = MockData.categories;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 6 : (width >= 600 ? 4 : 3);
    final childAspectRatio = width < 360 ? 0.8 : 0.9;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: BuyerDrawer(currentTabIndex: 1, onSelectTab: onSelectTab),
      appBar: JeapAppBar(showBack: false, onMenuTap: onOpenDrawer),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text('All Categories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: cats.length,
                itemBuilder: (_, i) => _CategoryTile(category: cats[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ProductCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CategoryProductsScreen(category: category)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon(category.icon),
                  color: AppTheme.jeapPurple, size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
