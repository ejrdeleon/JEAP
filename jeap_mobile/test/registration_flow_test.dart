import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/auth/models/registration_data.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/confirm_details_screen.dart';
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
        dateOfBirth: '01/15/1995',
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
      expect(json['date_of_birth'], '01/15/1995');
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
        dateOfBirth: '05/20/1998',
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
      expect(find.text('05/20/1998'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);

      final editBtn = find.text('EDIT DETAILS');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });
}
