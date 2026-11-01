import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';

class MockAuthServiceSuccess extends AuthService {
  @override
  Future<AuthResult> forgotPassword(String email) async {
    return const AuthResult(
      success: true,
      message: 'If an account exists with that email address, we have sent instructions to reset your password.',
      user: {'debug_code': '654321'},
    );
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (token != '654321') {
      return const AuthResult(
        success: false,
        message: 'The password reset code is invalid or has expired.',
      );
    }
    return const AuthResult(
      success: true,
      message: 'Your password has been reset successfully. Please log in with your new password.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Priority 9 — Forgot Password UI & Recovery Flow Tests', () {
    testWidgets('LoginScreen shows Forgot password? link and opens ForgotPasswordScreen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump();

      final forgotLink = find.text('Forgot password?');
      expect(forgotLink, findsOneWidget);

      await tester.tap(forgotLink);
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Send Recovery Code'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen validates email format before submitting',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
      await tester.pump();

      // Submit empty
      await tester.tap(find.text('Send Recovery Code'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address'), findsOneWidget);

      // Submit invalid email
      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.text('Send Recovery Code'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen validates 6-digit code and password matching',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(
            email: 'buyer@jeap.test',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.textContaining('buyer@jeap.test'), findsOneWidget);

      // Empty submit
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the recovery code'), findsOneWidget);

      // Enter short code
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '123');
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the full 6-digit code'), findsOneWidget);

      // Enter valid code, mismatched password
      await tester.enterText(fields.at(0), '123456');
      await tester.enterText(fields.at(1), 'password123');
      await tester.enterText(fields.at(2), 'mismatched');
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);

      // Short password (<8 chars)
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'short');
      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen toggles password obscure visibility',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(
            email: 'buyer@jeap.test',
            initialToken: '654321',
          ),
        ),
      );
      await tester.pump();

      // Locate visibility toggle buttons
      final iconButtons = find.byIcon(Icons.visibility_off_outlined);
      expect(iconButtons, findsNWidgets(2));

      await tester.tap(iconButtons.first);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
