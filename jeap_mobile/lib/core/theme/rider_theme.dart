import 'package:flutter/material.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';

/// Cohesive, professional color palette and semantic design system
/// for the JEAP Courier/Rider mobile experience.
///
/// Tailored for high-visibility outdoor usage, immediate visual feedback,
/// strong contrast (WCAG AA+ compliance), and clear status differentiation.
class RiderTheme {
  // Brand & Action Accents
  static const Color primaryBlue = Color(0xFF1D4ED8); // Blue 700 - high contrast
  static const Color primaryAction = Color(0xFF2563EB); // Blue 600
  static const Color secondaryAction = Color(0xFF475569); // Slate 600
  static const Color brandPurple = Color(0xFF4F46E5); // JEAP Parent Brand
  static const Color darkSlate = Color(0xFF0F172A); // Slate 900 for headers

  // Surfaces & Backgrounds optimized for bright outdoor daylight
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color cardColor = Colors.white;
  static const Color cardBorder = Color(0xFFCBD5E1); // Slate 300
  static const Color textDark = Color(0xFF0F172A); // High contrast text
  static const Color textMuted = Color(0xFF475569); // Slate 600

  // Semantic Status Colors
  // 1. Pending (Waiting for assignment / acceptance)
  static const Color statusPending = Color(0xFFB45309); // Amber 700
  static const Color statusPendingBg = Color(0xFFFEF3C7); // Amber 100

  // 2. Assigned (Assigned to rider)
  static const Color statusAssigned = Color(0xFF0369A1); // Sky 700
  static const Color statusAssignedBg = Color(0xFFE0F2FE); // Sky 100

  // 3. Pickup in Progress
  static const Color statusPickup = Color(0xFF4338CA); // Indigo 700
  static const Color statusPickupBg = Color(0xFFEEF2FF); // Indigo 100

  // 4. Out for Delivery / In Transit
  static const Color statusInTransit = Color(0xFF1D4ED8); // Blue 700
  static const Color statusInTransitBg = Color(0xFFDBEAFE); // Blue 100

  // 5. Successfully Delivered
  static const Color statusDelivered = Color(0xFF047857); // Emerald 700
  static const Color statusDeliveredBg = Color(0xFFD1FAE5); // Emerald 100

  // 6. Failed Attempt / Delivery Exception
  static const Color statusFailed = Color(0xFFB91C1C); // Red 700
  static const Color statusFailedBg = Color(0xFFFEE2E2); // Red 100

  // 7. Cancelled
  static const Color statusCancelled = Color(0xFF475569); // Slate 600
  static const Color statusCancelledBg = Color(0xFFE2E8F0); // Slate 200

  // 8. COD / Cash Accent
  static const Color codOrange = Color(0xFFC2410C); // Orange 700
  static const Color codOrangeBg = Color(0xFFFFEDD5); // Orange 100

  // Helper method returning semantic config for any TaskStatus
  static ({Color text, Color bg, IconData icon, String label}) statusConfig(
    TaskStatus status, {
    bool isPickup = false,
  }) {
    switch (status) {
      case TaskStatus.pending:
        return (
          text: statusPending,
          bg: statusPendingBg,
          icon: Icons.hourglass_top_rounded,
          label: isPickup ? 'Pending Pickup' : 'Pending Assignment',
        );
      case TaskStatus.accepted:
        return (
          text: statusAssigned,
          bg: statusAssignedBg,
          icon: Icons.assignment_turned_in_outlined,
          label: isPickup ? 'Pickup Assigned' : 'Delivery Assigned',
        );
      case TaskStatus.pickedUp:
        return (
          text: isPickup ? statusDelivered : statusInTransit,
          bg: isPickup ? statusDeliveredBg : statusInTransitBg,
          icon: isPickup ? Icons.inventory_2_outlined : Icons.two_wheeler_outlined,
          label: isPickup ? 'Picked Up from Seller' : 'Ready for Delivery',
        );
      case TaskStatus.outForDelivery:
        return (
          text: statusInTransit,
          bg: statusInTransitBg,
          icon: Icons.delivery_dining_outlined,
          label: 'Out for Delivery',
        );
      case TaskStatus.delivered:
        return (
          text: statusDelivered,
          bg: statusDeliveredBg,
          icon: Icons.check_circle_outline,
          label: isPickup ? 'Completed' : 'Successfully Delivered',
        );
      case TaskStatus.failed:
        return (
          text: statusFailed,
          bg: statusFailedBg,
          icon: Icons.report_problem_outlined,
          label: 'Delivery Issue Reported',
        );
    }
  }
}

/// A readable, accessible status badge widget that combines
/// semantic background color, high-contrast text, and an explicit icon.
class RiderStatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool isPickup;
  final String? customLabel;

  const RiderStatusBadge({
    super.key,
    required this.status,
    this.isPickup = false,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = RiderTheme.statusConfig(status, isPickup: isPickup);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.text.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.text),
          const SizedBox(width: 4),
          Text(
            customLabel ?? config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: config.text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
