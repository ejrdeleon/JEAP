import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/widgets/google_sign_in_button.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Logo & Google Button Tests', () {
    testWidgets('JeapLogo renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: JeapLogo(height: 50)),
        ),
      );
      expect(find.byType(JeapLogo), findsOneWidget);
    });

    testWidgets('GoogleSignInButton renders standard Google branding',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
    });
  });

  group('Login Screen Tests', () {
    testWidgets(
        'LoginScreen displays official JEAP logo, Remember me, and Google button',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JeapLogo), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });
  });

  group('Seller Badge Logic Tests', () {
    testWidgets('BuyerDrawer hides Seller badge when user is only a Buyer',
        (tester) async {
      await AuthSession.instance.setUser({
        'id': 1,
        'name': 'Regular Buyer',
        'email': 'buyer@example.com',
        'role': 'buyer',
        'roles': ['buyer'],
        'is_seller': false,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: BuyerDrawer(),
            body: Text('Home'),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Regular Buyer'), findsOneWidget);
      expect(find.text('buyer@example.com'), findsOneWidget);
      expect(find.text('Seller'), findsNothing);
    });

    testWidgets(
        'BuyerDrawer displays Seller badge when user has active Seller role',
        (tester) async {
      await AuthSession.instance.setUser({
        'id': 2,
        'name': 'Seller User',
        'email': 'seller@example.com',
        'role': 'buyer',
        'roles': ['buyer', 'seller'],
        'is_seller': true,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: BuyerDrawer(),
            body: Text('Home'),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Seller User'), findsOneWidget);
      expect(find.text('seller@example.com'), findsOneWidget);
      expect(find.text('Seller'), findsOneWidget);
    });
  });
}
