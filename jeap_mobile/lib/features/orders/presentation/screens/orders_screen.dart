import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:jeap_mobile/features/orders/services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    'All',
    'To Pay',
    'To Ship',
    'Delivering',
    'Completed',
    'Cancelled',
  ];

  final _orderService = OrderService();
  List<Order> _orders = [];
  bool _loading = true;

  Future<void> _load() async {
    try {
      final fetched = await _orderService.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = fetched;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
    OrderService.revision.addListener(_load);
  }

  @override
  void dispose() {
    OrderService.revision.removeListener(_load);
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _filtered(String tab) {
    if (tab == 'All') return _orders;
    if (tab == 'To Pay') {
      return _orders.where((o) => o.status == OrderStatus.toPay).toList();
    }
    if (tab == 'To Ship') {
      return _orders
          .where((o) =>
              o.status == OrderStatus.toShip ||
              o.status == OrderStatus.sellerPreparing)
          .toList();
    }
    if (tab == 'Delivering') {
      return _orders
          .where((o) =>
              o.status == OrderStatus.riderPickup ||
              o.status == OrderStatus.sortingCenter ||
              o.status == OrderStatus.assignedRider ||
              o.status == OrderStatus.outForDelivery ||
              o.status == OrderStatus.delivered)
          .toList();
    }
    if (tab == 'Completed') {
      return _orders.where((o) => o.status == OrderStatus.completed).toList();
    }
    if (tab == 'Cancelled') {
      return _orders
          .where((o) =>
              o.status == OrderStatus.cancelled ||
              o.status == OrderStatus.returnRefund)
          .toList();
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(showBack: false, showWishlist: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('My Orders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              labelColor: AppTheme.jeapPurple,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.jeapPurple,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  if (_loading && _orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final orders = _filtered(tab);
                  return RefreshIndicator(
                    onRefresh: _load,
                    child: orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text('No orders here.',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: orders.length,
                            itemBuilder: (_, i) => _OrderCard(
                              order: orders[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(order: orders[i]),
                                ),
                              ),
                            ),
                          ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.completed:
        return AppTheme.statusGreen;
      case OrderStatus.cancelled:
      case OrderStatus.returnRefund:
        return Colors.red;
      case OrderStatus.outForDelivery:
      case OrderStatus.delivered:
        return Colors.blue;
      default:
        return AppTheme.jeapPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.jeapPurple)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(order.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor)),
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(firstItem.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('x${firstItem.quantity}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      if (order.items.length > 1)
                        Text('+${order.items.length - 1} more item(s)',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Text('₱${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.priceRed,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('View Details →',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.jeapPurple,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
