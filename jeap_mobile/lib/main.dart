import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jeap_mobile/core/firebase/firebase_options.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/storage/token_storage.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';
import 'package:jeap_mobile/features/logistics/presentation/screens/logistics_dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.init();
  await AuthSession.instance.init();
  await ApiConfig.init();

  if (JeapFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(options: JeapFirebaseOptions.currentPlatform);
    } catch (_) {}
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  PaintingBinding.instance.imageCache.maximumSize = 250;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;

  runApp(const JeapApp());
}

class JeapApp extends StatelessWidget {
  const JeapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JEAP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const JeapStartupGate(),
    );
  }
}

class JeapStartupGate extends StatefulWidget {
  const JeapStartupGate({super.key});

  @override
  State<JeapStartupGate> createState() => _JeapStartupGateState();
}

class _JeapStartupGateState extends State<JeapStartupGate> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _activeUser;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await TokenStorage.get();
    if (token == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final user = await AuthService().me().timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _activeUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final cached = AuthSession.instance.currentUser;
        if (cached != null && cached['status'] == 'active') {
          setState(() {
            _activeUser = cached;
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _errorMessage =
              'Unable to connect to the server. Check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              JeapLogo(height: 72),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.jeapPurple),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const JeapLogo(height: 64),
                  const SizedBox(height: 32),
                  const Icon(Icons.cloud_off_outlined,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _checkInitialAuth,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.jeapPurple,
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      AuthSession.instance.setGuest(true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BuyerHomeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Explore as Guest'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.jeapPurple,
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      TokenStorage.clear();
                      setState(() {
                        _errorMessage = null;
                        _activeUser = null;
                      });
                    },
                    child: const Text('Go to Login Screen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final user = _activeUser;
    if (user == null || user['status'] != 'active') {
      return const LoginScreen();
    }

    final role = user['role']?.toString().toLowerCase();
    final roles = user['roles'] as List?;
    final isRider = role == 'rider' ||
        role == 'courier' ||
        (roles != null &&
            (roles.contains('rider') || roles.contains('courier')));
    final isLogistics = role == 'logistics' ||
        (roles != null && roles.contains('logistics'));

    if (isLogistics) {
      return const LogisticsDashboardScreen();
    }
    if (isRider) {
      return const RiderHomeScreen();
    }
    return const BuyerHomeScreen();
  }
}
