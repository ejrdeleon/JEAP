import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/token_storage.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/google_sign_in_button.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';

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
      final user = result.user;
      String role = 'buyer';
      if (user != null) {
        final r = user['role']?.toString().toLowerCase();
        final roles = user['roles'] as List?;
        final isRider = r == 'rider' ||
            r == 'courier' ||
            (roles != null &&
                (roles.contains('rider') || roles.contains('courier')));
        role = isRider ? 'rider' : 'buyer';
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'rider'
              ? const RiderHomeScreen()
              : const BuyerHomeScreen(),
        ),
        (_) => false,
      );
      return;
    }
    _showMessage(result.message);
  }

  void _showMessage(String message) {
    final lower = message.toLowerCase();
    final color = lower.contains('pending') || lower.contains('approval')
        ? Colors.orange.shade700
        : Colors.redAccent;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 5),
    ));
  }

  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot password?'),
        content: const Text(
          'Password reset is not available through the JEAP API yet. Please contact support for help with your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Center(
                      child: JeapLogo(height: 68),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 32),
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
                    const SizedBox(height: 22),
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
                    const SizedBox(height: 24),
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
