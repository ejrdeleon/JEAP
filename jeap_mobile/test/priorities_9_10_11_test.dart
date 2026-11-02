import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/theme/rider_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_avatar.dart';
import 'package:jeap_mobile/core/widgets/jeap_network_image.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Priority 9 — Forgot Password Tests', () {
    testWidgets('ForgotPasswordScreen renders input field and triggers validation',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.tap(find.text('Send Recovery Code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen validates 6-digit recovery code and password length',
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
      expect(find.text('6-Digit Recovery Code'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset Password'));
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the recovery code'), findsOneWidget);
    });
  });

  group('Priority 10 — Courier/Rider UI/UX and Color System Tests', () {
    test('RiderTheme semantic status configuration returns correct colors and icons', () {
      final pending = RiderTheme.statusConfig(TaskStatus.pending, isPickup: true);
      expect(pending.label, 'Pending Pickup');
      expect(pending.text, RiderTheme.statusPending);

      final inTransit = RiderTheme.statusConfig(TaskStatus.outForDelivery);
      expect(inTransit.label, 'Out for Delivery');
      expect(inTransit.text, RiderTheme.statusInTransit);

      final delivered = RiderTheme.statusConfig(TaskStatus.delivered);
      expect(delivered.label, 'Successfully Delivered');
      expect(delivered.text, RiderTheme.statusDelivered);

      final failed = RiderTheme.statusConfig(TaskStatus.failed);
      expect(failed.label, 'Delivery Issue Reported');
      expect(failed.text, RiderTheme.statusFailed);
    });

    testWidgets('RiderStatusBadge displays accessible status label and icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RiderStatusBadge(status: TaskStatus.outForDelivery),
                RiderStatusBadge(status: TaskStatus.delivered),
                RiderStatusBadge(status: TaskStatus.failed),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('Successfully Delivered'), findsOneWidget);
      expect(find.text('Delivery Issue Reported'), findsOneWidget);
      expect(find.byIcon(Icons.delivery_dining_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('RiderHomeScreen builds with high-contrast Courier theme header and tabs',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiderHomeScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Courier'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Chat'), findsAtLeastNWidgets(1));
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });
  });

  group('Priority 11 — Image Optimization Tests', () {
    test('PaintingBinding imageCache supports configured cache limits', () {
      PaintingBinding.instance.imageCache.maximumSize = 250;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
      expect(PaintingBinding.instance.imageCache.maximumSize, 250);
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes, 64 * 1024 * 1024);
    });

    testWidgets('JeapNetworkImage computes effective downsampled cacheWidth and cacheHeight',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JeapNetworkImage(
              imageUrl: 'http://127.0.0.1:8080/images/categories/cat-computers.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pump();

      final imgFinder = find.byType(Image);
      expect(imgFinder, findsOneWidget);

      final Image img = tester.widget(imgFinder);
      expect(img.image, isA<ResizeImage>());
      final resize = img.image as ResizeImage;
      expect(resize.width, 220);
      expect(resize.height, 220);
    });

    testWidgets('JeapAvatar uses cacheWidth and cacheHeight downsampling',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JeapAvatar(
              name: 'John Rider',
              imageUrl: 'http://127.0.0.1:8080/media/avatars/3',
              radius: 24,
            ),
          ),
        ),
      );
      await tester.pump();

      final imgFinder = find.byType(Image);
      expect(imgFinder, findsOneWidget);

      final Image img = tester.widget(imgFinder);
      expect(img.image, isA<ResizeImage>());
      final resize = img.image as ResizeImage;
      expect(resize.width, (24 * 4).round());
      expect(resize.height, (24 * 4).round());
    });
  });
}
