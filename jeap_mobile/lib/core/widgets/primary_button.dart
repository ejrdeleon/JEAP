import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Full-width purple pill button used across buyer screens
/// (Login, Sign Up, Add to Cart, Proceed to Checkout, etc.)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Colors.white),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.jeapPurple,
            side: const BorderSide(color: AppTheme.jeapPurple, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.jeapPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}
