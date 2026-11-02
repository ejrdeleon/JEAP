import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/models/product.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:jeap_mobile/features/seller/services/seller_service.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SellerService _sellerService = SellerService();
  late TabController _tabController;

  List<Order> _orders = [];
  List<Product> _products = [];
  bool _loadingOrders = true;
  bool _loadingProducts = true;
  String? _selectedOrderStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadOrders();
    _loadProducts();
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final orders = await _sellerService.fetchSellerOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final products = await _sellerService.fetchSellerProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _updateOrderStatus(Order order, String nextStatus) async {
    try {
      await _sellerService.updateOrderStatus(
        orderNumber: order.orderNumber,
        status: nextStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Order #${order.orderNumber} updated to ${nextStatus.replaceAll('_', ' ')}'),
            backgroundColor: AppTheme.statusGreen,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  List<Order> get _filteredOrders {
    if (_selectedOrderStatus == null || _selectedOrderStatus == 'ALL') {
      return _orders;
    }
    return _orders.where((o) {
      final s = o.status;
      switch (_selectedOrderStatus) {
        case 'PLACED':
          return s == OrderStatus.toPay;
        case 'CONFIRMED':
          return s == OrderStatus.toShip;
        case 'PREPARING':
          return s == OrderStatus.sellerPreparing;
        case 'READY_FOR_PICKUP':
          return s == OrderStatus.riderPickup;
        case 'COMPLETED':
          return s == OrderStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: Row(
          children: [
            const JeapLogo(height: 20),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.jeapPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SELLER CENTER',
                style: TextStyle(
                  color: AppTheme.jeapPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.jeapPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.jeapPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Store Orders'),
            Tab(icon: Icon(Icons.inventory, size: 18), text: 'Inventory'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersTab(),
            _buildInventoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _filterChip('ALL', 'All'),
              _filterChip('PLACED', 'New / Placed'),
              _filterChip('CONFIRMED', 'Confirmed'),
              _filterChip('PREPARING', 'Preparing'),
              _filterChip('READY_FOR_PICKUP', 'Ready for Pickup'),
              _filterChip('COMPLETED', 'Completed'),
            ],
          ),
        ),
        const Divider(height: 1),
        // Orders List
        Expanded(
          child: _loadingOrders && _orders.isEmpty
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.jeapPurple),
                )
              : _filteredOrders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 56, color: AppTheme.borderColor),
                          SizedBox(height: 12),
                          Text(
                            'No seller orders found',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: AppTheme.jeapPurple,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return _SellerOrderCard(
                            order: order,
                            onUpdateStatus: (next) =>
                                _updateOrderStatus(order, next),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(order: order),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String status, String label) {
    final isSelected = (_selectedOrderStatus ?? 'ALL') == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppTheme.jeapPurple.withValues(alpha: 0.15),
        onSelected: (sel) {
          setState(() {
            _selectedOrderStatus = sel ? status : 'ALL';
          });
        },
      ),
    );
  }

  Widget _buildInventoryTab() {
    return _loadingProducts && _products.isEmpty
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.jeapPurple),
          )
        : RefreshIndicator(
            onRefresh: _loadProducts,
            color: AppTheme.jeapPurple,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                final isLowStock = p.stock < 5;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: JeapNetworkImage(
                          imageUrl: p.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          fallback: const Icon(Icons.image_outlined,
                              size: 24, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₱${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.priceRed),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? Colors.redAccent.withValues(alpha: 0.12)
                              : AppTheme.statusGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLowStock
                              ? 'Low: ${p.stock} units'
                              : '${p.stock} in stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLowStock
                                ? Colors.redAccent
                                : AppTheme.statusGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final Order order;
  final ValueChanged<String> onUpdateStatus;
  final VoidCallback onTap;

  const _SellerOrderCard({
    required this.order,
    required this.onUpdateStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
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
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.priceRed),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.items.length} item(s) • ${order.paymentMethod}',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const Divider(height: 20),
            // Actions according to status
            Row(
              children: [
                OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                if (order.status == OrderStatus.toPay ||
                    order.status == OrderStatus.toShip) ...[
                  ElevatedButton(
                    onPressed: () => onUpdateStatus('confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.jeapPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Confirm Order',
                        style: TextStyle(fontSize: 12)),
                  ),
                ] else if (order.status == OrderStatus.sellerPreparing) ...[
                  ElevatedButton(
                    onPressed: () => onUpdateStatus('ready_for_pickup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Ready for Pickup',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
