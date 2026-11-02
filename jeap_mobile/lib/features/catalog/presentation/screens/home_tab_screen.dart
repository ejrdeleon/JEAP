import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/utils/category_icons.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/core/data/mock_data.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/features/catalog/services/catalog_service.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/search_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/categories_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/category_products_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/wishlist_screen.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notifications_screen.dart';

class HomeTabScreen extends StatefulWidget {
  final List<Product>? initialProducts;
  final VoidCallback? onOpenDrawer;

  const HomeTabScreen({
    super.key,
    this.initialProducts,
    this.onOpenDrawer,
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final CatalogService _catalogService = CatalogService();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      _products = widget.initialProducts!;
      _loading = false;
    } else {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (widget.initialProducts != null && _products.isNotEmpty) return;
    setState(() => _loading = true);
    try {
      final items = await _catalogService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = items.isNotEmpty ? items : MockData.products;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = MockData.products;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          color: AppTheme.jeapPurple,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: _buildBanner()),
              SliverToBoxAdapter(child: _buildQuickServicesRow(context)),
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Categories',
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategoryRow(context)),
              SliverToBoxAdapter(child: _buildSectionTitle('Best Sellers & Recommendations')),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppTheme.jeapPurple),
                    ),
                  ),
                )
              else
                _buildProductGrid(context),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.textPrimary, size: 24),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              tooltip: 'Navigation Menu',
              onPressed: () {
                if (widget.onOpenDrawer != null) {
                  widget.onOpenDrawer!();
                } else {
                  Scaffold.maybeOf(ctx)?.openDrawer();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'JEAP',
            style: TextStyle(
              color: AppTheme.jeapPurple,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.favorite_border,
                color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.notifications_outlined,
                color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chat_bubble_outline,
                color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BuyerConversationsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search products...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      constraints: const BoxConstraints(minHeight: 125),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.jeapPurple.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🚚 FREE NATIONWIDE SHIPPING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome to JEAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Discover authentic products & daily deals.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServicesRow(BuildContext context) {
    final services = [
      {'icon': Icons.bolt, 'label': 'Flash Deals', 'color': Colors.amber.shade700},
      {'icon': Icons.local_shipping_outlined, 'label': 'Free Shipping', 'color': AppTheme.jeapPurple},
      {'icon': Icons.verified_outlined, 'label': 'Authentic', 'color': AppTheme.statusGreen},
      {'icon': Icons.confirmation_number_outlined, 'label': 'Vouchers', 'color': Colors.deepOrange},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: services.map((s) {
          return Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(initialQuery: s['label'] as String),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (s['color'] as Color).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 19),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: const Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.jeapPurple,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.jeapPurple),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context) {
    const cats = MockData.topCategories;
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CategoryProductsScreen(category: cat)),
            ),
            child: Container(
              width: 68,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(categoryIcon(cat.icon),
                        color: AppTheme.jeapPurple, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final products = _products;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
    final childAspectRatio = width < 360 ? 0.56 : (width < 600 ? 0.58 : 0.65);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(
            product: products[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: products[i])),
            ),
          ),
          childCount: products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
      ),
    );
  }
}
