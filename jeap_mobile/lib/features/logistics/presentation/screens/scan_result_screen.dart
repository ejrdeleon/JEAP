import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/logistics/models/logistics_parcel.dart';
import 'package:jeap_mobile/features/logistics/services/logistics_service.dart';

class ScanResultScreen extends StatefulWidget {
  final LogisticsParcel parcel;
  final String? currentAction;

  const ScanResultScreen({
    super.key,
    required this.parcel,
    this.currentAction,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final LogisticsService _service = LogisticsService();
  bool _processing = false;
  late LogisticsParcel _parcel;
  String? _statusMessage;
  bool _statusSuccess = false;

  @override
  void initState() {
    super.initState();
    _parcel = widget.parcel;
  }

  Future<void> _handleAction(String action) async {
    setState(() {
      _processing = true;
      _statusMessage = null;
    });

    final res = await _service.scanParcel(
      identifier: _parcel.trackingNumber,
      action: action,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final updated = await _service.getParcel(_parcel.trackingNumber);
      setState(() {
        _processing = false;
        _statusSuccess = true;
        _statusMessage = res['message'] ?? 'Action $action processed successfully';
        if (updated != null) {
          _parcel = updated;
        }
      });
    } else {
      setState(() {
        _processing = false;
        _statusSuccess = false;
        _statusMessage = res['message'] ?? 'Error processing action';
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'CONFIRMED':
      case 'PREPARING':
        return Colors.blue;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
        return Colors.indigo;
      case 'AT_SORTING_CENTER':
      case 'PACKED':
        return Colors.orange;
      case 'SORTED':
      case 'SHIPPED':
        return Colors.teal;
      case 'ASSIGNED_TO_RIDER':
      case 'OUT_FOR_DELIVERY':
        return AppTheme.jeapPurple;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Parcel Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'STANDARD EXPRESS',
                          style: TextStyle(
                            color: AppTheme.jeapPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_parcel.status)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _parcel.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(_parcel.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _parcel.trackingNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Order #${_parcel.orderNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.person_outline, 'Recipient',
                      '${_parcel.recipientName} (${_parcel.recipientPhone})'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.place_outlined, 'Destination',
                      _parcel.destinationAddress),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                      Icons.warehouse_outlined, 'Origin Hub', _parcel.originHub),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.inventory_2_outlined, 'Package',
                      '${_parcel.itemsCount} Item(s) • ${_parcel.paymentMethod} • ₱${_parcel.totalAmount.toStringAsFixed(2)}'),
                ],
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _statusSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusSuccess ? Colors.green.shade800 : Colors.red.shade800,
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
            const Text(
              'Warehouse Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.move_to_inbox,
                  label: 'Receive at Hub',
                  color: Colors.blue,
                  onTap: _processing ? null : () => _handleAction('receive'),
                ),
                _buildActionButton(
                  icon: Icons.alt_route,
                  label: 'Sort to Bay',
                  color: Colors.orange,
                  onTap: _processing ? null : () => _handleAction('sort'),
                ),
                _buildActionButton(
                  icon: Icons.local_shipping,
                  label: 'Dispatch to Fleet',
                  color: Colors.teal,
                  onTap: _processing ? null : () => _handleAction('dispatch'),
                ),
                _buildActionButton(
                  icon: Icons.sync_alt,
                  label: 'Hub Transfer',
                  color: AppTheme.jeapPurple,
                  onTap: _processing ? null : () => _handleAction('transfer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
