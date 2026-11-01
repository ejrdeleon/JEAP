import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_chat_screen.dart';
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
  bool _cancelling = false;
  bool _submittingReturn = false;

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

  bool get _canCancel {
    return _order.status == OrderStatus.toPay ||
        _order.status == OrderStatus.toShip ||
        _order.status == OrderStatus.sellerPreparing;
  }

  bool get _canReturn {
    return _order.status == OrderStatus.delivered ||
        _order.status == OrderStatus.completed;
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
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RatingScreen(order: _order)),
    );
  }

  void _showCancelDialog() {
    String selectedReason = 'Changed my mind';
    final reasons = [
      'Changed my mind',
      'Found cheaper alternative elsewhere',
      'Incorrect delivery address or details',
      'Need to modify items or variation',
      'Ordered by mistake',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cancel Order',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select a reason for cancelling this order:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ...reasons.map((r) => InkWell(
                    onTap: () => setDialogState(() => selectedReason = r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == r
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selectedReason == r
                                ? AppTheme.jeapPurple
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r, style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _cancelling = true);
                try {
                  await OrderService()
                      .cancelOrder(_order.orderNumber, selectedReason);
                  final updated =
                      await OrderService().fetchOrder(_order.orderNumber);
                  if (mounted) {
                    setState(() {
                      _cancelling = false;
                      if (updated != null) _order = updated;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled successfully.'),
                        backgroundColor: AppTheme.statusGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _cancelling = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to cancel order. Please try again.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirm Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnDialog() {
    String selectedReason = 'damaged_item';
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Return / Refund',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for return/refund:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'damaged_item', child: Text('Damaged Item')),
                    DropdownMenuItem(
                        value: 'wrong_item', child: Text('Wrong Item Received')),
                    DropdownMenuItem(
                        value: 'not_as_described',
                        child: Text('Not as Described')),
                    DropdownMenuItem(
                        value: 'other', child: Text('Other Issue')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedReason = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Details / Notes (optional):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the problem with your parcel...',
                    hintStyle:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.jeapPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final desc = descCtrl.text.trim();
                Navigator.pop(ctx);
                setState(() => _submittingReturn = true);
                try {
                  await OrderService().requestReturn(
                    orderNumber: _order.orderNumber,
                    reason: selectedReason,
                    description: desc.isNotEmpty ? desc : null,
                  );
                  final updated =
                      await OrderService().fetchOrder(_order.orderNumber);
                  if (mounted) {
                    setState(() {
                      _submittingReturn = false;
                      if (updated != null) _order = updated;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Return request submitted successfully!'),
                        backgroundColor: AppTheme.statusGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _submittingReturn = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not submit return request.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
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
              const SizedBox(height: 16),

              // Chat about order button
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Chat with Seller about this order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.jeapPurple,
                  side: const BorderSide(color: AppTheme.jeapPurple),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerChatScreen(
                        conversation: Conversation(
                          id: 1,
                          participantName: 'Seller (${_order.orderNumber})',
                          participantRole: 'seller',
                          lastMessage: 'Regarding Order #${_order.orderNumber}',
                          lastMessageAt: DateTime.now(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

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
              if (_order.status == OrderStatus.delivered) ...[
                PrimaryButton(
                  label: 'CONFIRM ORDER RECEIVED',
                  onPressed: _confirmReceived,
                  loading: _confirming,
                ),
                const SizedBox(height: 12),
              ],

              // Return / Refund button
              if (_canReturn) ...[
                PrimaryButton(
                  label: 'REQUEST RETURN / REFUND',
                  outlined: true,
                  onPressed: _submittingReturn ? null : _showReturnDialog,
                  loading: _submittingReturn,
                ),
                const SizedBox(height: 12),
              ],

              // Rate button for completed orders
              if (_order.status == OrderStatus.completed) ...[
                PrimaryButton(
                  label: 'RATE THIS ORDER',
                  outlined: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RatingScreen(order: _order)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Cancel button for placed/confirmed orders
              if (_canCancel) ...[
                OutlinedButton(
                  onPressed: _cancelling ? null : _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.buyerRadius),
                    ),
                  ),
                  child: _cancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.redAccent),
                        )
                      : const Text(
                          'CANCEL ORDER',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
              ],

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isDone ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Item Row ─────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              imageUrl: item.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              fallback: const Icon(Icons.image_outlined,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
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
          Text(
            '₱${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.priceRed,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Info Section ─────────────────────────────────────────────────────────────
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
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Summary Row ──────────────────────────────────────────────────────────────
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
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? AppTheme.textPrimary : AppTheme.textSecondary)),
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

// ── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
