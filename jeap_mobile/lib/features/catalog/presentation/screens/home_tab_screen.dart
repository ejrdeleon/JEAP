import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/models/category.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/utils/category_icons.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/core/widgets/product_card.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/category_products_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/search_screen.dart';
import 'package:jeap_mobile/features/catalog/services/catalog_service.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/messaging/services/message_service.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:jeap_mobile/features/notifications/services/notification_service.dart';

class HomeTabScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onSelectTab;

  const HomeTabScreen({
    super.key,
    this.onOpenDrawer,
    this.onSelectTab,
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _catalogService = CatalogService();
  final _messageService = MessageService();
  final _notificationService = NotificationService();

  List<ProductCategory> _categories = [];
  List<Product> _products = [];
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _catalogService.fetchCategories(),
        _catalogService.fetchProducts(),
        _notificationService.fetchNotifications().catchError(
            (_) => const NotificationResult(unreadCount: 0, notifications: [])),
        _messageService
            .fetchConversations()
            .catchError((_) => <Conversation>[]),
      ]);

      if (mounted) {
        final notifRes = results[2] as NotificationResult;
        final convs = results[3] as List<Conversation>;
        final unreadMsgs = convs.fold<int>(0, (sum, c) => sum + c.unreadCount);

        setState(() {
          _categories = results[0] as List<ProductCategory>;
          _products = results[1] as List<Product>;
          _unreadNotifications = notifRes.unreadCount;
          _unreadMessages = unreadMsgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load products. Please check server connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBadges() async {
    try {
      final notifRes = await _notificationService.fetchNotifications();
      final convs = await _messageService.fetchConversations();
      final unreadMsgs = convs.fold<int>(0, (sum, c) => sum + c.unreadCount);
      if (mounted) {
        setState(() {
          _unreadNotifications = notifRes.unreadCount;
          _unreadMessages = unreadMsgs;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.jeapPurple,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: _buildBanner(context)),
              SliverToBoxAdapter(child: _buildQuickShortcuts(context)),
              SliverToBoxAdapter(child: _buildSectionTitle('Categories')),
              SliverToBoxAdapter(child: _buildCategoryRow(context)),
              SliverToBoxAdapter(child: _buildSectionTitle('Best Sellers')),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.jeapPurple),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, size: 18),
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
              else if (_products.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No products available right now.',
                          style: TextStyle(color: AppTheme.textSecondary)),
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
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: AuthSession.instance.userNotifier,
      builder: (context, user, _) {
        final isSeller = AuthSession.instance.isSeller;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu,
                    color: AppTheme.textPrimary, size: 24),
                tooltip: 'Open menu',
                onPressed: widget.onOpenDrawer,
              ),
              const SizedBox(width: 2),
              const JeapLogo(height: 30),
              if (isSeller)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.jeapPurple.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.jeapPurple.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_outlined,
                          size: 11, color: AppTheme.jeapPurple),
                      SizedBox(width: 3),
                      Text(
                        'Seller',
                        style: TextStyle(
                          color: AppTheme.jeapPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Notification Bell with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppTheme.textPrimary, size: 24),
                    tooltip: 'Notifications',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      );
                      _refreshBadges();
                    },
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: Text(
                          _unreadNotifications > 9
                              ? '9+'
                              : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Messages Button with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: AppTheme.textPrimary, size: 22),
                    tooltip: 'Messages',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BuyerConversationsScreen()),
                      );
                      _refreshBadges();
                    },
                  ),
                  if (_unreadMessages > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.jeapPurple,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: Text(
                          _unreadMessages > 9 ? '9+' : '$_unreadMessages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
            SizedBox(width: 10),
            Text(
              'Search products, brands, and categories...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.jeapPurple, AppTheme.jeapDarkPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.jeapPurple.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to JEAP!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Discover authentic deals and seamless delivery.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => widget.onSelectTab?.call(2), // go to cart
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.jeapPurple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 14),
                      SizedBox(width: 6),
                      Text('View Cart',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const JeapLogo(height: 38, width: 100),
        ],
      ),
    );
  }

  Widget _buildQuickShortcuts(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _shortcutItem(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: () => widget.onSelectTab?.call(3),
          ),
          _shortcutItem(
            icon: Icons.local_shipping_outlined,
            label: 'To Receive',
            onTap: () => widget.onSelectTab?.call(3),
          ),
          _shortcutItem(
            icon: Icons.assignment_return_outlined,
            label: 'Returns',
            onTap: () => widget.onSelectTab?.call(3),
          ),
          _shortcutItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Categories',
            onTap: () => widget.onSelectTab?.call(1),
          ),
        ],
      ),
    );
  }

  Widget _shortcutItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.jeapPurple, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context) {
    if (_categories.isEmpty && _isLoading) {
      return const SizedBox(
        height: 84,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.jeapPurple),
          ),
        ),
      );
    }

    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CategoryProductsScreen(category: cat)),
            ),
            child: Container(
              width: 74,
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
                  const SizedBox(height: 5),
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive aspect ratio to avoid overflow on small or narrow devices
    final childAspectRatio =
        screenWidth < 360 ? 0.65 : (screenWidth > 600 ? 0.8 : 0.70);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(
            product: _products[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: _products[i])),
            ),
          ),
          childCount: _products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 600 ? 3 : 2,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
      ),
    );
  }
}
