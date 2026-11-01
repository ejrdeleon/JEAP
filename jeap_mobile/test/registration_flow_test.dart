import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/auth/models/registration_data.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/confirm_details_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/email_otp_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/signup_screen.dart';

void main() {
  group('RegistrationData Model Tests', () {
    test('Correctly maps properties, getters, and toJson payload for Laravel',
        () {
      const data = RegistrationData(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'juan@example.com',
        mobileNumber: '+639123456789',
        dateOfBirth: '1995-01-15',
        gender: 'Male',
        houseNumber: '123',
        street: 'Rizal St',
        barangay: 'Barangay 1',
        city: 'Lumban',
        province: 'Laguna',
        zipCode: '4014',
        password: 'Password123!',
      );

      expect(data.fullName, 'Juan Dela Cruz');
      expect(data.maskedPassword, '••••••••');

      final json = data.toJson();
      expect(json['first_name'], 'Juan');
      expect(json['last_name'], 'Dela Cruz');
      expect(json['email'], 'juan@example.com');
      expect(json['phone'], '+639123456789');
      expect(json['date_of_birth'], '1995-01-15');
      expect(json['gender'], 'Male');
      expect(json['house_number'], '123');
      expect(json['street'], 'Rizal St');
      expect(json['barangay'], 'Barangay 1');
      expect(json['city'], 'Lumban');
      expect(json['province'], 'Laguna');
      expect(json['zip_code'], '4014');
      expect(json['password'], 'Password123!');
      expect(json['password_confirmation'], 'Password123!');
    });

    test('fullName includes middle initial when provided', () {
      const data = RegistrationData(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        middleInitial: 'A',
        email: 'juan@example.com',
        mobileNumber: '+639123456789',
        gender: 'Male',
        houseNumber: '123',
        street: 'Rizal St',
        barangay: 'Barangay 1',
        city: 'Lumban',
        province: 'Laguna',
        zipCode: '4014',
        password: 'Password123!',
      );
      expect(data.fullName, 'Juan A. Dela Cruz');
    });

    test('age is calculated and stored correctly', () {
      const data = RegistrationData(
        firstName: 'Maria',
        lastName: 'Santos',
        email: 'maria@example.com',
        mobileNumber: '09123456789',
        gender: 'Female',
        houseNumber: '5',
        street: 'Mabini St',
        barangay: 'Barangay 2',
        city: 'Santa Cruz',
        province: 'Laguna',
        zipCode: '4009',
        password: 'Secret99!',
        age: 26,
      );
      expect(data.age, 26);
    });
  });

  group('Registration UI Flow Tests', () {
    testWidgets(
        'SignUpScreen renders without overflow on small device widths (320px)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsWidgets);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(errorDetails, isNull);
    });

    testWidgets(
        'ConfirmDetailsScreen renders all review fields and EDIT DETAILS pops',
        (tester) async {
      const testData = RegistrationData(
        firstName: 'Maria',
        lastName: 'Santos',
        email: 'maria@example.com',
        mobileNumber: '09123456789',
        dateOfBirth: '1998-05-20',
        gender: 'Female',
        houseNumber: 'Block 5 Lot 10',
        street: 'Maharlika Hwy',
        barangay: 'Barangay 2',
        city: 'Santa Cruz',
        province: 'Laguna',
        zipCode: '4009',
        password: 'SecretPassword99!',
      );

      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (_) => popped = true,
            pages: const [
              MaterialPage(
                child: ConfirmDetailsScreen(registrationData: testData),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Your Details'), findsOneWidget);
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('maria@example.com'), findsOneWidget);
      expect(find.text('09123456789'), findsOneWidget);
      expect(find.text('1998-05-20'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);

      final editBtn = find.text('EDIT DETAILS');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets(
        'SignUpScreen triggers validation errors when submitted empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final continueBtn = find.text('CONTINUE');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Contact number is required'), findsOneWidget);
      expect(find.text('Birthday is required'), findsOneWidget);
      expect(find.text('ZIP code is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('EmailOtpScreen renders 6-digit input boxes and expiry timer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const EmailOtpScreen(email: 'buyer@example.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.textContaining('buyer@example.com'), findsOneWidget);
      expect(find.text('VERIFY & CONTINUE'), findsOneWidget);
      expect(find.textContaining('Code expires in'), findsOneWidget);
      expect(find.textContaining('Resend'), findsOneWidget);

      // Verify exactly 6 input fields are present
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(6));
    });
  });
}
