import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/theme/rider_theme.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';
import 'package:jeap_mobile/features/tasks/services/rider_assignment_service.dart';

class ProofOfDeliverySheet extends StatefulWidget {
  final DeliveryTask task;
  final String imagePath;
  final VoidCallback onRetake;

  const ProofOfDeliverySheet({
    super.key,
    required this.task,
    required this.imagePath,
    required this.onRetake,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DeliveryTask task,
    required String imagePath,
    required VoidCallback onRetake,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofOfDeliverySheet(
        task: task,
        imagePath: imagePath,
        onRetake: onRetake,
      ),
    );
  }

  @override
  State<ProofOfDeliverySheet> createState() => _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends State<ProofOfDeliverySheet> {
  final _service = RiderAssignmentService();
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _submitProof() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await _service.completeDelivery(widget.task.id, widget.imagePath);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Could not submit proof of delivery. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: RiderTheme.primaryBlue, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Confirm Proof of Delivery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RiderTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Order: ${widget.task.trackingNumber} • Recipient: ${widget.task.contactName}',
              style: const TextStyle(fontSize: 13, color: RiderTheme.textMuted),
            ),
            const SizedBox(height: 16),

            // Captured Image Preview
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.65),
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: _submitting
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                              widget.onRetake();
                            },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retake', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.task.codAmount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RiderTheme.codOrangeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RiderTheme.codOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: RiderTheme.codOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'COD Collected: ₱${widget.task.codAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: RiderTheme.codOrange,
                        ),
                      ),
                    ),
                    const Icon(Icons.check_circle, color: RiderTheme.codOrange, size: 18),
                  ],
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RiderTheme.statusFailedBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RiderTheme.statusFailed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: RiderTheme.statusFailed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: RiderTheme.statusFailed,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submitProof,
                    style: FilledButton.styleFrom(
                      backgroundColor: RiderTheme.statusDelivered,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Confirm Delivery',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
