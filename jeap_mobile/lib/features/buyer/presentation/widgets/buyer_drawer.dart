import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/help_support_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/manage_addresses_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notifications_screen.dart';

class BuyerDrawer extends StatelessWidget {
  final ValueChanged<int>? onSelectTab;
  final int currentTabIndex;

  const BuyerDrawer({
    super.key,
    this.onSelectTab,
    this.currentTabIndex = 0,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _sectionHeader('SHOPPING'),
                  _drawerItem(
                    context: context,
                    icon:
                        currentTabIndex == 0 ? Icons.home : Icons.home_outlined,
                    title: 'Home',
                    isSelected: currentTabIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 1
                        ? Icons.grid_view
                        : Icons.grid_view_outlined,
                    title: 'Categories',
                    isSelected: currentTabIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 2
                        ? Icons.shopping_cart
                        : Icons.shopping_cart_outlined,
                    title: 'My Cart',
                    isSelected: currentTabIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 3
                        ? Icons.receipt_long
                        : Icons.receipt_long_outlined,
                    title: 'My Orders',
                    isSelected: currentTabIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(3);
                    },
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 4
                        ? Icons.person
                        : Icons.person_outline,
                    title: 'Account Overview',
                    isSelected: currentTabIndex == 4,
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(4);
                    },
                  ),
                  const SizedBox(height: 8),
                  _sectionHeader('COMMUNICATION'),
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
                  const SizedBox(height: 8),
                  _sectionHeader('ACCOUNT PREFERENCES'),
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
                    icon: Icons.edit_outlined,
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
                    icon: Icons.tune_outlined,
                    title: 'Notification Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _sectionHeader('SUPPORT'),
                  _drawerItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _drawerItem(
                context: context,
                icon: Icons.logout,
                title: 'Log Out',
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                onTap: () => _confirmLogout(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'JEAP E-Commerce v2.0 • Philippines',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
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
        final avatarUrl = AuthSession.instance.avatarUrl;

        final initials = name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .where((s) => s.isNotEmpty)
                .take(2)
                .map((s) => s[0].toUpperCase())
                .join()
            : 'J';

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const JeapLogo(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.jeapPurple.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppTheme.jeapPurple.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSeller
                                ? Icons.store_outlined
                                : Icons.verified_user_outlined,
                            size: 12,
                            color: AppTheme.jeapPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSeller ? 'Seller' : 'Buyer',
                            style: const TextStyle(
                              color: AppTheme.jeapPurple,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppTheme.jeapPurple.withValues(alpha: 0.12),
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.jeapPurple,
                              ),
                            )
                          : null,
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
                              fontSize: 14.5,
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
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ],
            ),
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
    bool isSelected = false,
    Color iconColor = AppTheme.textPrimary,
    Color textColor = AppTheme.textPrimary,
  }) {
    final effectiveIconColor = isSelected ? AppTheme.jeapPurple : iconColor;
    final effectiveTextColor = isSelected ? AppTheme.jeapPurple : textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: isSelected
            ? AppTheme.jeapPurple.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(icon, color: effectiveIconColor, size: 21),
          title: Text(
            title,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.jeapPurple,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: onTap,
        ),
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
