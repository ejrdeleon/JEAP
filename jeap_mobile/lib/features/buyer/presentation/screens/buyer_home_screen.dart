import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/home_tab_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/categories_screen.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';

class BuyerHomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final List<Product>? initialProducts;
  final List<BuyerCartItem>? initialCartItems;
  final List<Order>? initialOrders;
  final Map<String, dynamic>? initialUser;

  const BuyerHomeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialProducts,
    this.initialCartItems,
    this.initialOrders,
    this.initialUser,
  });

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onSelectTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> _buildTabs() => [
        HomeTabScreen(
          onOpenDrawer: _openDrawer,
          initialProducts: widget.initialProducts,
        ),
        CategoriesScreen(onOpenDrawer: _openDrawer, onSelectTab: _onSelectTab),
        CartScreen(
          onOpenDrawer: _openDrawer,
          onSelectTab: _onSelectTab,
          initialItems: widget.initialCartItems,
        ),
        OrdersScreen(
          onOpenDrawer: _openDrawer,
          onSelectTab: _onSelectTab,
          initialOrders: widget.initialOrders,
        ),
        AccountScreen(
          onOpenDrawer: _openDrawer,
          onSelectTab: _onSelectTab,
          initialUser: widget.initialUser,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTabletOrDesktop = width >= 768;
    final tabs = _buildTabs();

    if (isTabletOrDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: BuyerDrawer(
          currentTabIndex: _currentIndex,
          onSelectTab: (i) => setState(() => _currentIndex = i),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              indicatorColor: AppTheme.jeapPurple.withValues(alpha: 0.15),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: AppTheme.jeapPurple),
                  tooltip: 'Full Menu',
                  onPressed: _openDrawer,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppTheme.jeapPurple),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view, color: AppTheme.jeapPurple),
                  label: Text('Categories'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  selectedIcon: Icon(Icons.shopping_cart, color: AppTheme.jeapPurple),
                  label: Text('Cart'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long, color: AppTheme.jeapPurple),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppTheme.jeapPurple),
                  label: Text('Account'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppTheme.borderColor),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: tabs),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: BuyerDrawer(
        currentTabIndex: _currentIndex,
        onSelectTab: (i) => setState(() => _currentIndex = i),
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.jeapPurple.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.jeapPurple),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: AppTheme.jeapPurple),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: AppTheme.jeapPurple),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.jeapPurple),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.jeapPurple),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
