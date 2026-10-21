import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/manage_addresses_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notifications_screen.dart';

class BuyerDrawer extends StatelessWidget {
  final ValueChanged<int>? onSelectTab;

  const BuyerDrawer({
    super.key,
    this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildUserHeader(context),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.grid_view_outlined,
                    title: 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.shopping_cart_outlined,
                    title: 'My Cart',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(3);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BuyerConversationsScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(height: 1),
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Addresses',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageAddressesScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _drawerItem(
              context: context,
              icon: Icons.logout,
              title: 'Log Out',
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: AuthSession.instance.userNotifier,
      builder: (context, user, _) {
        final name = AuthSession.instance.displayName;
        final email = AuthSession.instance.email;
        final isSeller = AuthSession.instance.isSeller;

        final initials = name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .where((s) => s.isNotEmpty)
                .take(2)
                .map((s) => s[0].toUpperCase())
                .join()
            : 'J';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const JeapLogo(height: 30),
                  if (isSeller)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.jeapPurple.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppTheme.jeapPurple.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 13,
                            color: AppTheme.jeapPurple,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Seller',
                            style: TextStyle(
                              color: AppTheme.jeapPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppTheme.jeapPurple.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.jeapPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textPrimary,
    Color textColor = AppTheme.textPrimary,
  }) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance with your orders, deliveries, or account?'),
            SizedBox(height: 12),
            Text(
              'Customer Service: support@jeap.store\nOperating Hours: 8:00 AM - 8:00 PM',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
            'Are you sure you want to log out of your JEAP account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
