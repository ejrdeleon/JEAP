import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/theme/rider_theme.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';
import 'package:jeap_mobile/features/tasks/presentation/widgets/proof_of_delivery_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('forgot_password_screen screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ForgotPasswordScreen(
          initialEmail: 'buyer@jeap.test',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ForgotPasswordScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/forgot_password_screen.png'),
    );
  });

  testWidgets('reset_password_screen screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ResetPasswordScreen(
          email: 'buyer@jeap.test',
          initialToken: '492810',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ResetPasswordScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/reset_password_screen.png'),
    );
  });

  testWidgets('courier_dashboard screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const RiderHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RiderHomeScreen),
      matchesGoldenFile('../../screenshots/jeap_mobile/courier_dashboard.png'),
    );
  });

  testWidgets('assigned_deliveries screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleTasks = [
      const DeliveryTask(
        id: '1',
        trackingNumber: 'JEAP-DEL-882194',
        contactName: 'Maria Santos',
        contactPhone: '09171234567',
        deliveryAddress: 'Unit 402 Tower B, Greenfield District, Mandaluyong City',
        status: TaskStatus.outForDelivery,
        isPickup: false,
        payout: 50.00,
        codAmount: 750.00,
        attemptNumber: 1,
      ),
      const DeliveryTask(
        id: '2',
        trackingNumber: 'JEAP-DEL-882195',
        contactName: 'Alex Ramos',
        contactPhone: '09189876543',
        deliveryAddress: '15 Diamond St., Pasig City, Metro Manila',
        status: TaskStatus.accepted,
        isPickup: false,
        payout: 50.00,
        codAmount: 0.00,
        attemptNumber: 1,
      ),
      const DeliveryTask(
        id: '3',
        trackingNumber: 'JEAP-DEL-882196',
        contactName: 'TechHub Store Seller',
        contactPhone: '09228889999',
        deliveryAddress: 'JEAP Hub Central, Quezon City',
        status: TaskStatus.pending,
        isPickup: true,
        payout: 30.00,
        codAmount: 0.00,
        attemptNumber: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: RiderTheme.background,
          appBar: AppBar(
            backgroundColor: RiderTheme.primaryBlue,
            title: const Text('Assigned Deliveries'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sampleTasks.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sampleTasks[i].trackingNumber,
                              style: const TextStyle(
                                color: RiderTheme.brandPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: RiderTheme.statusDeliveredBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Payout: ₱${sampleTasks[i].payout.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: RiderTheme.statusDelivered,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sampleTasks[i].contactName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: RiderTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sampleTasks[i].deliveryAddress,
                        maxLines: 2,
                        style: const TextStyle(
                          color: RiderTheme.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          RiderStatusBadge(
                            status: sampleTasks[i].status,
                            isPickup: sampleTasks[i].isPickup,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: sampleTasks[i].codAmount > 0
                                  ? RiderTheme.codOrangeBg
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sampleTasks[i].codAmount > 0
                                  ? 'COD: ₱${sampleTasks[i].codAmount.toStringAsFixed(2)}'
                                  : 'Prepaid',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: sampleTasks[i].codAmount > 0
                                    ? RiderTheme.codOrange
                                    : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: RiderTheme.primaryAction,
                              minimumSize: const Size(70, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('View', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../../screenshots/jeap_mobile/assigned_deliveries.png'),
    );
  });

  testWidgets('proof_of_delivery screenshot', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const sampleTask = DeliveryTask(
      id: '1',
      trackingNumber: 'JEAP-DEL-882194',
      contactName: 'Maria Santos',
      contactPhone: '09171234567',
      deliveryAddress: 'Unit 402 Tower B, Greenfield District, Mandaluyong City',
      status: TaskStatus.outForDelivery,
      isPickup: false,
      payout: 50.00,
      codAmount: 750.00,
      attemptNumber: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: ProofOfDeliverySheet(
              task: sampleTask,
              imagePath: 'assets/images/jeap_logo.png',
              onRetake: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProofOfDeliverySheet),
      matchesGoldenFile('../../screenshots/jeap_mobile/proof_of_delivery.png'),
    );
  });
}
