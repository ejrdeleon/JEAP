import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:jeap_mobile/features/orders/services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onSelectTab;
  final List<Order>? initialOrders;

  const OrdersScreen({
    super.key,
    this.onOpenDrawer,
    this.onSelectTab,
    this.initialOrders,
  });

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
    'To Receive',
    'Completed',
    'Cancelled',
    'Return/Refund',
  ];

  final _orderService = OrderService();
  List<Order> _orders = [];
  bool _loading = true;

  Future<void> _load() async {
    if (widget.initialOrders != null && _orders.isNotEmpty && OrderService.revision.value == 0) {
      return;
    }
    if (AuthSession.instance.isGuest) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _loading = false;
      });
      return;
    }
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
    if (widget.initialOrders != null) {
      _orders = List.from(widget.initialOrders!);
      _loading = false;
    } else {
      _load();
    }
    OrderService.revision.addListener(_load);
  }

  @override
  void dispose() {
    OrderService.revision.removeListener(_load);
    _tabController.dispose();
    super.dispose();
  }

  bool _isCod(Order o) {
    final pm = o.paymentMethod.toLowerCase();
    return pm.contains('cod') || pm.contains('cash');
  }

  List<Order> _filtered(String tab) {
    if (tab == 'All') return _orders;
    if (tab == 'To Pay') {
      return _orders
          .where((o) => o.status == OrderStatus.toPay && !_isCod(o))
          .toList();
    }
    if (tab == 'To Ship') {
      return _orders
          .where((o) =>
              o.status == OrderStatus.toShip ||
              o.status == OrderStatus.sellerPreparing ||
              (o.status == OrderStatus.toPay && _isCod(o)))
          .toList();
    }
    if (tab == 'To Receive') {
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
      return _orders.where((o) => o.status == OrderStatus.cancelled).toList();
    }
    if (tab == 'Return/Refund') {
      return _orders.where((o) => o.status == OrderStatus.returnRefund).toList();
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    if (AuthSession.instance.isGuest) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        drawer: BuyerDrawer(currentTabIndex: 3, onSelectTab: widget.onSelectTab),
        appBar: JeapAppBar(showBack: false, showWishlist: false, onMenuTap: widget.onOpenDrawer),
        body: const SafeArea(
          child: GuestPromptView(
            title: 'Track Your Orders',
            message:
                'Sign in to your JEAP account to view live order tracking, download invoices, and request returns or refunds.',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: BuyerDrawer(currentTabIndex: 3, onSelectTab: widget.onSelectTab),
      appBar: JeapAppBar(showBack: false, showWishlist: false, onMenuTap: widget.onOpenDrawer),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: AppTheme.jeapPurple,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.jeapPurple,
                indicatorWeight: 2.5,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading && _orders.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.jeapPurple))
                  : TabBarView(
                      controller: _tabController,
                      children: _tabs.map((t) => _buildList(t)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String tab) {
    final list = _filtered(tab);
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.jeapPurple,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppTheme.borderColor),
                  const SizedBox(height: 16),
                  Text('No $tab orders',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.jeapPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (_, i) => _OrderCard(
          order: list[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: list[i])),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const Divider(height: 16),
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.inputFill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          child: JeapNetworkImage(
                            imageUrl: item.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            fallback: const Icon(Icons.image_outlined,
                                size: 20, color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )),
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '+${order.items.length - 2} more item(s)',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} item(s)',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Total: ₱${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.priceRed,
                        fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case OrderStatus.toPay:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade800;
        label = 'To Pay';
        break;
      case OrderStatus.toShip:
      case OrderStatus.sellerPreparing:
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue.shade700;
        label = 'To Ship';
        break;
      case OrderStatus.riderPickup:
      case OrderStatus.sortingCenter:
      case OrderStatus.assignedRider:
      case OrderStatus.outForDelivery:
      case OrderStatus.delivered:
        bg = AppTheme.jeapPurple.withValues(alpha: 0.12);
        fg = AppTheme.jeapPurple;
        label = status == OrderStatus.delivered ? 'Delivered' : 'Delivering';
        break;
      case OrderStatus.completed:
        bg = AppTheme.statusGreen.withValues(alpha: 0.15);
        fg = AppTheme.statusGreen;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red;
        label = 'Cancelled';
        break;
      case OrderStatus.returnRefund:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        label = 'Return/Refund';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
