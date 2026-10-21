import 'package:flutter/material.dart';
import '../../../../../../theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';

class RegistrationPendingScreen extends StatelessWidget {
  const RegistrationPendingScreen({super.key});

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
                  color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 48, color: AppTheme.jeapPurple),
              ),
              const SizedBox(height: 28),
              const Text(
                'Registration Submitted!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your registration has been submitted successfully. '
                'Please wait for administrator approval. '
                'You will receive an email once your account has been approved.',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'You will not be able to log in until your account is approved.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                label: 'BACK TO LOGIN',
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
