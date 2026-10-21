import 'package:flutter/material.dart';
import '../../../../../../theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.statusGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 52, color: AppTheme.statusGreen),
              ),
              const SizedBox(height: 24),
              const Text('Order Placed!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Your order has been placed successfully. '
                'The seller will prepare your items shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                label: 'TRACK MY ORDER',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'CONTINUE SHOPPING',
                outlined: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
