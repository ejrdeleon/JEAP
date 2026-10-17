import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/orders/models/order.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/rating_screen.dart';
import 'package:jeap_mobile/features/orders/services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  bool _confirming = false;

  static const _timeline = [
    (OrderStatus.toPay, 'Order Placed'),
    (OrderStatus.toShip, 'Payment Confirmed'),
    (OrderStatus.sellerPreparing, 'Seller Preparing'),
    (OrderStatus.riderPickup, 'Rider Pickup'),
    (OrderStatus.sortingCenter, 'Sorting Center'),
    (OrderStatus.assignedRider, 'Rider Assigned'),
    (OrderStatus.outForDelivery, 'Out for Delivery'),
    (OrderStatus.delivered, 'Delivered'),
    (OrderStatus.completed, 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  int get _currentStep {
    final idx = _timeline.indexWhere((t) => t.$1 == _order.status);
    return idx < 0 ? 0 : idx;
  }

  Future<void> _confirmReceived() async {
    setState(() => _confirming = true);
    final service = OrderService();
    try {
      await service.confirmReceived(_order.orderNumber);
      final updated = await service.fetchOrder(_order.orderNumber);
      if (!mounted) return;
      setState(() {
        _confirming = false;
        if (updated != null) _order = updated;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not confirm receipt. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order confirmed as received!'),
        backgroundColor: AppTheme.statusGreen,
      ),
    );
    // Prompt rating
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RatingScreen(order: _order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_order.orderNumber,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  _StatusBadge(status: _order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Placed on ${_formatDate(_order.createdAt)}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Tracking timeline
              if (_order.status != OrderStatus.cancelled &&
                  _order.status != OrderStatus.returnRefund) ...[
                const Text('Order Tracking',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _TrackingTimeline(steps: _timeline, currentStep: _currentStep),
                const SizedBox(height: 20),
              ],

              // Items
              const Text('Items',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._order.items.map((item) => _ItemRow(item: item)),
              const SizedBox(height: 16),

              // Delivery address
              _InfoSection(
                title: 'Delivery Address',
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.jeapPurple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_order.deliveryAddress,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment
              _InfoSection(
                title: 'Payment Method',
                child: Row(
                  children: [
                    const Icon(Icons.payment_outlined,
                        color: AppTheme.jeapPurple, size: 18),
                    const SizedBox(width: 8),
                    Text(_order.paymentMethod,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Summary
              _InfoSection(
                title: 'Order Summary',
                child: Column(
                  children: [
                    _SummaryRow(
                        'Subtotal', '₱${_order.subtotal.toStringAsFixed(2)}'),
                    if (_order.discount > 0)
                      _SummaryRow('Discount',
                          '- ₱${_order.discount.toStringAsFixed(2)}',
                          valueColor: AppTheme.statusGreen),
                    _SummaryRow('Delivery Fee',
                        '₱${_order.deliveryFee.toStringAsFixed(2)}'),
                    const Divider(height: 14),
                    _SummaryRow(
                      'Total',
                      '₱${_order.total.toStringAsFixed(2)}',
                      bold: true,
                      valueColor: AppTheme.priceRed,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Confirm received button
              if (_order.status == OrderStatus.delivered)
                PrimaryButton(
                  label: 'CONFIRM ORDER RECEIVED',
                  onPressed: _confirmReceived,
                  loading: _confirming,
                ),

              // Rate button for completed orders
              if (_order.status == OrderStatus.completed)
                PrimaryButton(
                  label: 'RATE THIS ORDER',
                  outlined: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RatingScreen(order: _order)),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ── Tracking Timeline ────────────────────────────────────────────────────────
class _TrackingTimeline extends StatelessWidget {
  final List<(OrderStatus, String)> steps;
  final int currentStep;

  const _TrackingTimeline({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final label = e.value.$2;
        final isDone = i <= currentStep;
        final isCurrent = i == currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppTheme.jeapPurple : AppTheme.borderColor,
                    border: isCurrent
                        ? Border.all(color: AppTheme.jeapPurple, width: 2)
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: i < currentStep
                        ? AppTheme.jeapPurple
                        : AppTheme.borderColor,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_outlined,
                color: AppTheme.textSecondary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (item.variations.isNotEmpty)
                  Text(
                    item.variations.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(', '),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                Text('x${item.quantity}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text('₱${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.priceRed)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
