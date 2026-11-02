import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/orders/services/order_service.dart';

class RatingScreen extends StatefulWidget {
  final Order order;
  const RatingScreen({super.key, required this.order});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _reviewCtrls = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      _ratings[item.productId] = 5;
      _reviewCtrls[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _reviewCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final service = OrderService();
      for (final item in widget.order.items) {
        await service.submitRating(
          orderNumber: widget.order.orderNumber,
          productId: item.productId,
          rating: _ratings[item.productId] ?? 5,
          review: _reviewCtrls[item.productId]?.text.trim() ?? '',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit feedback. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: AppTheme.statusGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate Your Order',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Order ${widget.order.orderNumber}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 20),
                    ...widget.order.items.map((item) => _RatingCard(
                          item: item,
                          rating: _ratings[item.productId] ?? 5,
                          reviewCtrl: _reviewCtrls[item.productId]!,
                          onRatingChanged: (v) =>
                              setState(() => _ratings[item.productId] = v),
                        )),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.white,
              child: PrimaryButton(
                label: 'SUBMIT FEEDBACK',
                onPressed: _submit,
                loading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final OrderItem item;
  final double rating;
  final TextEditingController reviewCtrl;
  final ValueChanged<double> onRatingChanged;

  const _RatingCard({
    required this.item,
    required this.rating,
    required this.reviewCtrl,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: JeapNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  fallback: const Icon(Icons.image_outlined,
                      color: AppTheme.textSecondary, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Your Rating',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final starVal = (i + 1).toDouble();
              return GestureDetector(
                onTap: () => onRatingChanged(starVal),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    rating >= starVal ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Text('Write a Review (optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: reviewCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product...',
            ),
          ),
        ],
      ),
    );
  }
}
