import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:jeap_mobile/features/account/models/address.dart';
import 'package:jeap_mobile/features/account/services/address_service.dart';
import 'package:jeap_mobile/features/orders/services/order_service.dart';
import 'package:jeap_mobile/features/checkout/presentation/screens/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<BuyerCartItem> items;
  final double subtotal;

  const CheckoutScreen(
      {super.key, required this.items, required this.subtotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AddressService _addressService = AddressService();
  List<Address> _addresses = [];
  int? _selectedAddressId;
  bool _loadingAddresses = true;
  String? _addressError;

  final String _paymentMethod = 'cod';

  final _voucherCtrl = TextEditingController();
  double _discount = 0;
  String? _appliedVoucher;
  bool _applyingVoucher = false;

  static const _deliveryFee = 50.0;

  double get _total => widget.subtotal - _discount + _deliveryFee;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _addressService.fetchAddresses();
      if (!mounted) return;
      final selected = addresses.isEmpty
          ? null
          : addresses.firstWhere(
              (address) => address.isDefault,
              orElse: () => addresses.first,
            );
      setState(() {
        _addresses = addresses;
        _selectedAddressId = selected?.id;
        _loadingAddresses = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _addressError = error.toString();
        _loadingAddresses = false;
      });
    }
  }

  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _applyingVoucher = true);
    try {
      final discount = await OrderService().validateVoucher(
        code: code,
        subtotal: widget.subtotal,
      );
      if (!mounted) return;
      setState(() {
        _discount = discount;
        _appliedVoucher = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher applied! ₱${discount.toStringAsFixed(2)} off'),
          backgroundColor: AppTheme.statusGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _discount = 0;
        _appliedVoucher = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not validate voucher.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _applyingVoucher = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please save and select a delivery address.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await OrderService().placeOrder(
        addressId: _selectedAddressId!,
        cartItemIds: widget.items.map((item) => item.id).toList(),
        paymentMethod: _paymentMethod,
        voucherCode: _appliedVoucher,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not place your order. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      (route) => route.isFirst,
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Checkout',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // ── Order Items ──────────────────────────────────────
                    _sectionTitle('Order Items'),
                    ...widget.items.map((item) => _OrderItemRow(item: item)),
                    const SizedBox(height: 16),

                    // ── Voucher ──────────────────────────────────────────
                    _sectionTitle('Voucher / Discount'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.buyerRadius),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _voucherCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Enter voucher code',
                                border: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _applyingVoucher ? null : _applyVoucher,
                            child: _applyingVoucher
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Apply',
                                    style: TextStyle(
                                        color: AppTheme.jeapPurple,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    if (_appliedVoucher != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppTheme.statusGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                              'Voucher "$_appliedVoucher" applied — ₱${_discount.toStringAsFixed(2)} off',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.statusGreen)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ── Delivery Address ─────────────────────────────────
                    _sectionTitle('Delivery Address'),
                    if (_loadingAddresses)
                      const Center(child: CircularProgressIndicator())
                    else if (_addresses.isEmpty)
                      _InfoCard(
                        child: Text(
                          _addressError ??
                              'No saved delivery addresses were found. Add an address before checkout.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: _selectedAddressId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Choose a saved address',
                        ),
                        items: _addresses
                            .where((address) => address.id != null)
                            .map(
                              (address) => DropdownMenuItem<int>(
                                value: address.id,
                                child: Text(
                                  '${address.label}: ${address.fullAddress}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) =>
                            setState(() => _selectedAddressId = id),
                      ),
                    const SizedBox(height: 16),

                    // ── Payment Method ───────────────────────────────────
                    _sectionTitle('Payment Method'),
                    const _InfoCard(
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined,
                              color: AppTheme.jeapPurple, size: 20),
                          SizedBox(width: 10),
                          Text('Cash on Delivery',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Order Summary ────────────────────────────────────
                    _sectionTitle('Order Summary'),
                    _InfoCard(
                      child: Column(
                        children: [
                          _SummaryRow('Subtotal',
                              '₱${widget.subtotal.toStringAsFixed(2)}'),
                          if (_discount > 0)
                            _SummaryRow('Discount',
                                '- ₱${_discount.toStringAsFixed(2)}',
                                valueColor: AppTheme.statusGreen),
                          _SummaryRow('Delivery Fee',
                              '₱${_deliveryFee.toStringAsFixed(2)}'),
                          const Divider(height: 16),
                          _SummaryRow(
                            'Total',
                            '₱${_total.toStringAsFixed(2)}',
                            bold: true,
                            valueColor: AppTheme.priceRed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.white,
              child: PrimaryButton(
                label: 'PLACE ORDER  ₱${_total.toStringAsFixed(2)}',
                onPressed: _placeOrder,
                loading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

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
      child: child,
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final BuyerCartItem item;
  const _OrderItemRow({required this.item});

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
            width: 52,
            height: 52,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
