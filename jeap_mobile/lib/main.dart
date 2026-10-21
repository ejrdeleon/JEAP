import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jeap_mobile/core/firebase/firebase_options.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/storage/token_storage.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.init();
  await AuthSession.instance.init();
  if (JeapFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(options: JeapFirebaseOptions.currentPlatform);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      home: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService().me(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null || user['status'] != 'active') {
            return const LoginScreen();
          }
          final r = user['role']?.toString().toLowerCase();
          final roles = user['roles'] as List?;
          final isRider = r == 'rider' ||
              r == 'courier' ||
              (roles != null &&
                  (roles.contains('rider') || roles.contains('courier')));
          return isRider ? const RiderHomeScreen() : const BuyerHomeScreen();
        },
      ),
    );
  }
}
