import 'package:jeap_mobile/core/storage/guest_cart_manager.dart';
import 'package:jeap_mobile/features/cart/services/cart_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/storage/token_storage.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/google_sign_in_button.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/core/widgets/server_settings_sheet.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/email_otp_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/logistics_dashboard_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedData();
  }

  Future<void> _loadRememberedData() async {
    final remember = await TokenStorage.isRememberMeEnabled();
    final savedEmail = await TokenStorage.getRememberedEmail();
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailCtrl.text = savedEmail;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    await TokenStorage.saveRememberedEmail(email, _rememberMe);
    final result = await _authService.login(
      email,
      _passwordCtrl.text,
      rememberMe: _rememberMe,
    );
    await _finishSignIn(result);
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    await _finishSignIn(await _authService.signInWithGoogle());
  }

  Future<void> _finishSignIn(AuthResult result) async {
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      AuthSession.instance.setGuest(false);
      await GuestCartManager.instance.mergeIntoAccount(CartService());
      final user = result.user;
      String role = 'buyer';
      if (user != null) {
        final r = user['role']?.toString().toLowerCase();
        final roles = user['roles'] as List?;
        final isRider = r == 'rider' ||
            r == 'courier' ||
            (roles != null &&
                (roles.contains('rider') || roles.contains('courier')));
        final isLogistics = r == 'logistics' ||
            (roles != null && roles.contains('logistics'));
        if (isLogistics) {
          role = 'logistics';
        } else if (isRider) {
          role = 'rider';
        } else {
          role = 'buyer';
        }
      }

      Widget targetScreen;
      if (role == 'logistics') {
        targetScreen = const LogisticsDashboardScreen();
      } else if (role == 'rider') {
        targetScreen = const RiderHomeScreen();
      } else {
        targetScreen = const BuyerHomeScreen();
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
        (_) => false,
      );
      return;
    }
    _showMessage(result.message);
  }

  void _showMessage(String message) {
    final lower = message.toLowerCase();
    final isUnverified = lower.contains('verify your email') ||
        lower.contains('unverified') ||
        lower.contains('verification');
    final isPending = lower.contains('pending') || lower.contains('approval');
    final isConnectionError = lower.contains('connect') ||
        lower.contains('connection') ||
        lower.contains('server') ||
        lower.contains('network') ||
        lower.contains('timed out');

    final color = (isUnverified || isPending)
        ? Colors.orange.shade700
        : Colors.redAccent;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: (isUnverified || isConnectionError) ? 8 : 5),
      action: isConnectionError
          ? SnackBarAction(
              label: 'SETTINGS',
              textColor: Colors.white,
              onPressed: () => ServerSettingsSheet.show(context),
            )
          : (isUnverified
              ? SnackBarAction(
                  label: 'VERIFY',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmailOtpScreen(email: _emailCtrl.text.trim()),
                      ),
                    );
                  },
                )
              : null),
    ));
  }

  void _showForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: _emailCtrl.text.trim(),
        ),
      ),
    );
  }

  void _handleContinueAsGuest() {
    AuthSession.instance.setGuest(true);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BuyerHomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.dns_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: 'Server Environment Settings',
                        onPressed: () => ServerSettingsSheet.show(context),
                      ),
                    ),
                    const Center(
                      child: JeapLogo(height: 68),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Color(0xFF25283D),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Center(
                      child: Text(
                        'Log in to your account',
                        style: TextStyle(
                          color: Color(0xFF9297A8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _FieldLabel('E-mail or Contact No.'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email or contact number',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter your email address';
                        if (!RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(text)) {
                          return 'The server currently accepts email sign-in only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Password'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) => setState(
                                        () => _rememberMe = value ?? false,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      activeColor: AppTheme.jeapPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Remember me',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _showForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppTheme.jeapPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.jeapPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GoogleSignInButton(
                      isLoading: _loading,
                      onPressed: _handleGoogleLogin,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF9297A8),
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
                              style: const TextStyle(
                                color: AppTheme.jeapPurple,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderColor)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Color(0xFF9297A8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderColor)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _handleContinueAsGuest,
                        icon: const Icon(Icons.explore_outlined, size: 20),
                        label: const Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.jeapPurple,
                          side: const BorderSide(
                              color: AppTheme.jeapPurple, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: Color(0xFF81879A),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}
