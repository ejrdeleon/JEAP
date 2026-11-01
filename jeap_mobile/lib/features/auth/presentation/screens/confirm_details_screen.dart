import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/auth/models/registration_data.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/email_otp_screen.dart';

class ConfirmDetailsScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const ConfirmDetailsScreen({super.key, required this.registrationData});

  @override
  State<ConfirmDetailsScreen> createState() => _ConfirmDetailsScreenState();
}

class _ConfirmDetailsScreenState extends State<ConfirmDetailsScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _handleConfirm() async {
    setState(() => _loading = true);
    final result = await _authService.register(widget.registrationData);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(email: widget.registrationData.email),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.registrationData;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text('Sign Up',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              const Text('Confirm Your Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Review your information before submitting.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ),
                  Text('Step 2 of 2',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.jeapPurple)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 6,
                  backgroundColor: AppTheme.borderColor,
                  color: AppTheme.jeapPurple,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('PERSONAL INFORMATION'),
              const SizedBox(height: 10),
              _ReviewCard(items: [
                _Item('Full Name', d.fullName),
                _Item('Email', d.email),
                _Item('Contact Number', d.mobileNumber),
                _Item('Birthday', d.dateOfBirth ?? 'Not specified'),
                if (d.age != null) _Item('Age', '${d.age} years old'),
                _Item('Sex', d.gender),
              ]),
              const SizedBox(height: 20),
              const _SectionLabel('ADDRESS'),
              const SizedBox(height: 10),
              _ReviewCard(items: [
                _Item('Province', d.province),
                _Item('City / Municipality', d.city),
                _Item('Barangay', d.barangay),
                _Item('House No.', d.houseNumber),
                _Item('Street', d.street),
                if (d.subdivision != null) _Item('Subdivision', d.subdivision!),
                if (d.buildingUnit != null)
                  _Item('Building / Unit', d.buildingUnit!),
                _Item('ZIP Code', d.zipCode),
              ]),
              const SizedBox(height: 20),
              const _SectionLabel('IDENTIFICATION'),
              const SizedBox(height: 10),
              if (d.idImagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  child: Image.file(
                    File(d.idImagePath!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Text('No ID uploaded',
                    style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              const _SectionLabel('ACCOUNT SECURITY'),
              const SizedBox(height: 10),
              _ReviewCard(items: [
                _Item('Password', d.maskedPassword),
                const _Item('Terms & Conditions', 'Agreed'),
              ]),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your account will be reviewed by an administrator. '
                        'You will receive an email once approved.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'SUBMIT REGISTRATION',
                onPressed: _handleConfirm,
                loading: _loading,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'EDIT DETAILS',
                onPressed: _loading ? null : () => Navigator.pop(context),
                outlined: true,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final List<_Item> items;
  const _ReviewCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(e.value.label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: Text(e.value.value,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, thickness: 0.5, color: AppTheme.borderColor),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Item {
  final String label;
  final String value;
  const _Item(this.label, this.value);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.jeapPurple,
            letterSpacing: 0.5));
  }
}
