import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/categories_screen.dart';
import 'package:jeap_mobile/features/catalog/presentation/screens/home_tab_screen.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  void _onSelectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTabScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onSelectTab: _onSelectTab,
      ),
      const CategoriesScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: BuyerDrawer(onSelectTab: _onSelectTab),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onSelectTab,
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
