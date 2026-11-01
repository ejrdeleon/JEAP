import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/network/api_config.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_avatar.dart';
import 'package:jeap_mobile/core/widgets/server_settings_sheet.dart';
import 'package:jeap_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:jeap_mobile/features/orders/presentation/screens/orders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiConfig Unit Tests', () {
    test('Default baseUrl points to local API endpoint', () {
      expect(ApiConfig.baseUrl, contains('/api/v1'));
      expect(ApiConfig.serverBaseUrl, isNot(contains('/api/v1')));
    });

    test('resolveImageUrl normalizes relative paths', () {
      final resolved = ApiConfig.resolveImageUrl('/media/avatars/42');
      expect(resolved, isNotNull);
      expect(resolved, startsWith('http'));
      expect(resolved, endsWith('/media/avatars/42'));
    });

    test('resolveImageUrl normalizes raw avatar storage paths', () {
      final resolved = ApiConfig.resolveImageUrl('avatars/42/photo.jpg');
      expect(resolved, isNotNull);
      expect(resolved, contains('/media/avatars/42/photo.jpg'));
    });

    test('resolveImageUrl appends cacheBust timestamp', () {
      final resolved = ApiConfig.resolveImageUrl('/media/avatars/42', cacheBust: true);
      expect(resolved, contains('v='));
    });

    test('resolveImageUrl preserves external data URIs', () {
      const dataUri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      expect(ApiConfig.resolveImageUrl(dataUri), equals(dataUri));
    });

    test('resolveImageUrl rewrites localhost to active server authority when different', () async {
      await ApiConfig.setBaseUrl('http://192.168.28.104:8080/api/v1');
      final rewritten = ApiConfig.resolveImageUrl('http://127.0.0.1:8080/media/avatars/5');
      expect(rewritten, contains('192.168.28.104:8080'));
      // Reset
      await ApiConfig.resetBaseUrl();
    });
  });

  group('AuthSession & Guest State Tests', () {
    test('setGuest toggles isGuest and clears active user', () {
      final session = AuthSession.instance;
      session.setGuest(true);
      expect(session.isGuest, isTrue);
      expect(session.isAuthenticated, isFalse);
      expect(session.displayName, equals('Guest User'));
      expect(session.avatarUrl, isNull);

      session.setUser({'id': 1, 'name': 'Maria Santos', 'role': 'buyer'});
      expect(session.isGuest, isFalse);
      expect(session.isAuthenticated, isTrue);
      expect(session.displayName, equals('Maria Santos'));
    });
  });

  group('Guest Mode UI & Widgets Tests', () {
    testWidgets('LoginScreen displays Continue as Guest and Server Settings button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
    });

    testWidgets('GuestPromptView renders title, message, and sign in actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: GuestPromptView(
              title: 'Your Cart is Waiting',
              message: 'Sign in to access your saved cart items.',
              icon: Icons.shopping_cart_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Your Cart is Waiting'), findsOneWidget);
      expect(find.text('Sign in to access your saved cart items.'), findsOneWidget);
      expect(find.text('Log In to Your Account'), findsOneWidget);
      expect(find.text('Create an Account'), findsOneWidget);
    });

    testWidgets('CartScreen displays GuestPromptView when in guest mode', (tester) async {
      AuthSession.instance.setGuest(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CartScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GuestPromptView), findsOneWidget);
      expect(find.text('Your Cart is Waiting'), findsOneWidget);
    });

    testWidgets('OrdersScreen displays GuestPromptView when in guest mode', (tester) async {
      AuthSession.instance.setGuest(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OrdersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GuestPromptView), findsOneWidget);
      expect(find.text('Track Your Orders'), findsOneWidget);
    });

    testWidgets('AccountScreen displays GuestPromptView when in guest mode', (tester) async {
      AuthSession.instance.setGuest(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GuestPromptView), findsOneWidget);
      expect(find.text('Your Account'), findsOneWidget);
    });

    testWidgets('JeapAvatar renders initials cleanly when imageUrl is null or empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: JeapAvatar(
              name: 'Juan Dela Cruz',
              radius: 30,
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('ServerSettingsSheet shows environment presets and custom input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ServerSettingsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Server Environment'), findsOneWidget);
      expect(find.text('Localhost / USB ADB Reverse'), findsOneWidget);
      expect(find.text('Android Emulator Host'), findsOneWidget);
      expect(find.text('Production Server'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Save & Apply'), findsOneWidget);
    });
  });
}
