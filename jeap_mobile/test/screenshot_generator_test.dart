import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/server_settings_sheet.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01_login_screen_guest_mode', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/01_login_screen_guest_mode.png'),
    );
  });

  testWidgets('02_server_settings_presets', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SizedBox(
            width: double.infinity,
            child: ServerSettingsSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ServerSettingsSheet),
      matchesGoldenFile('../../screenshots/jeap_mobile/02_server_settings_presets.png'),
    );
  });

  testWidgets('03_guest_cart_protection', (tester) async {
    AuthSession.instance.setGuest(true);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const CartScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CartScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/03_guest_cart_protection.png'),
    );
  });

  testWidgets('04_guest_orders_protection', (tester) async {
    AuthSession.instance.setGuest(true);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const OrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OrdersScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/04_guest_orders_protection.png'),
    );
  });

  testWidgets('05_guest_account_protection', (tester) async {
    AuthSession.instance.setGuest(true);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AccountScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AccountScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/05_guest_account_protection.png'),
    );
  });

  testWidgets('06_buyer_drawer_guest', (tester) async {
    AuthSession.instance.setGuest(true);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: BuyerDrawer(currentTabIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BuyerDrawer),
      matchesGoldenFile('../../screenshots/jeap_mobile/06_buyer_drawer_guest.png'),
    );
  });

  testWidgets('07_account_screen_authenticated', (tester) async {
    AuthSession.instance.setUser({
      'id': 1,
      'first_name': 'Maria',
      'last_name': 'Santos',
      'name': 'Maria Santos',
      'email': 'maria.santos@jeap.store',
      'role': 'buyer',
      'status': 'active',
      'avatar_url': 'http://127.0.0.1:8080/media/avatars/1',
    });
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AccountScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AccountScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/07_account_screen_authenticated.png'),
    );
  });
}
