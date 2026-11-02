import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/primary_button.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/registration_pending_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;

  const EmailOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _errorMessage;

  // 15-minute validity timer (900 seconds)
  static const int _initialExpirySeconds = 15 * 60;
  int _expirySeconds = _initialExpirySeconds;
  Timer? _expiryTimer;

  // 60-second resend cooldown timer
  static const int _resendCooldownSeconds = 60;
  int _cooldownSeconds = _resendCooldownSeconds;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startExpiryTimer();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expirySeconds = _initialExpirySeconds;
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_expirySeconds > 0) {
        setState(() => _expirySeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = _resendCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedExpiry {
    final minutes = _expirySeconds ~/ 60;
    final seconds = _expirySeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste of multiple characters
      _handlePaste(value);
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otpCode.length == 6) {
          _handleVerify();
        }
      }
    }
  }

  void _handlePaste(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < 6; i++) {
      if (i < digits.length) {
        _controllers[i].text = digits[i];
      } else {
        _controllers[i].clear();
      }
    }

    final nextIndex = digits.length < 6 ? digits.length : 5;
    _focusNodes[nextIndex].requestFocus();

    if (digits.length >= 6) {
      _focusNodes[5].unfocus();
      _handleVerify();
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpCode.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the verification code.');
      return;
    }

    if (_expirySeconds <= 0) {
      setState(() => _errorMessage = 'The verification code has expired. Please request a new one.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _authService.verifyEmail(widget.email, code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      final user = result.user;
      final status = user?['status']?.toString().toLowerCase();

      if (status == 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account successfully activated! Welcome to JEAP.'),
            backgroundColor: AppTheme.statusGreen,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BuyerHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationPendingScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _authService.resendEmailVerification(widget.email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startExpiryTimer();
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.statusGreen,
        ),
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _expirySeconds <= 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: AppTheme.jeapPurple,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a 6-digit verification code to:\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // 6 OTP Digit Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      height: 56,
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace &&
                              _controllers[index].text.isEmpty &&
                              index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLength: 1,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppTheme.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppTheme.jeapPurple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (val) => _onDigitChanged(index, val),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Expiry timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isExpired ? Colors.redAccent : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpired
                          ? 'Code expired'
                          : 'Code expires in $_formattedExpiry',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isExpired ? Colors.redAccent : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                PrimaryButton(
                  label: 'VERIFY & CONTINUE',
                  onPressed: _handleVerify,
                  loading: _loading,
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the code?",
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: (_cooldownSeconds == 0 && !_loading) ? _handleResend : null,
                      child: Text(
                        _cooldownSeconds > 0
                            ? 'Resend ($_cooldownSeconds s)'
                            : 'Resend Code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _cooldownSeconds > 0
                              ? AppTheme.textSecondary
                              : AppTheme.jeapPurple,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
