import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_avatar.dart';
import 'package:jeap_mobile/core/widgets/jeap_logo.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/help_support_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/manage_addresses_screen.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:jeap_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:jeap_mobile/features/seller/presentation/screens/seller_dashboard_screen.dart';

class BuyerDrawer extends StatelessWidget {
  final ValueChanged<int>? onSelectTab;
  final int currentTabIndex;

  const BuyerDrawer({
    super.key,
    this.onSelectTab,
    this.currentTabIndex = 0,
  });

  void _navigateTab(BuildContext context, int index) {
    Navigator.pop(context);
    if (onSelectTab != null) {
      onSelectTab!(index);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BuyerHomeScreen(initialTabIndex: index),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = AuthSession.instance.isGuest;

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
                    onTap: () => _navigateTab(context, 0),
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 1
                        ? Icons.grid_view
                        : Icons.grid_view_outlined,
                    title: 'Categories',
                    isSelected: currentTabIndex == 1,
                    onTap: () => _navigateTab(context, 1),
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 2
                        ? Icons.shopping_cart
                        : Icons.shopping_cart_outlined,
                    title: 'My Cart',
                    isSelected: currentTabIndex == 2,
                    onTap: () => _navigateTab(context, 2),
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 3
                        ? Icons.receipt_long
                        : Icons.receipt_long_outlined,
                    title: 'My Orders',
                    isSelected: currentTabIndex == 3,
                    onTap: () => _navigateTab(context, 3),
                  ),
                  _drawerItem(
                    context: context,
                    icon: currentTabIndex == 4
                        ? Icons.person
                        : Icons.person_outline,
                    title: 'Account Overview',
                    isSelected: currentTabIndex == 4,
                    onTap: () => _navigateTab(context, 4),
                  ),
                  const SizedBox(height: 8),
                  if (AuthSession.instance.isSeller) ...[
                    _sectionHeader('SELLER CENTER'),
                    _drawerItem(
                      context: context,
                      icon: Icons.storefront_outlined,
                      title: 'Seller Dashboard',
                      iconColor: AppTheme.jeapPurple,
                      textColor: AppTheme.jeapPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellerDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  _sectionHeader('COMMUNICATION'),
                  _drawerItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    onTap: () {
                      if (isGuest) {
                        showGuestActionDialog(
                          context,
                          title: 'Messages',
                          message: 'Please log in to view your chat conversations.',
                        );
                        return;
                      }
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
                      if (isGuest) {
                        showGuestActionDialog(
                          context,
                          title: 'Notifications',
                          message: 'Please log in to view your notifications.',
                        );
                        return;
                      }
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
                      if (isGuest) {
                        showGuestActionDialog(
                          context,
                          title: 'Delivery Addresses',
                          message: 'Please log in to manage your delivery addresses.',
                        );
                        return;
                      }
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
                      if (isGuest) {
                        showGuestActionDialog(
                          context,
                          title: 'Edit Profile',
                          message: 'Please log in to edit your profile details.',
                        );
                        return;
                      }
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
                      if (isGuest) {
                        showGuestActionDialog(
                          context,
                          title: 'Change Password',
                          message: 'Please log in to change your password.',
                        );
                        return;
                      }
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
                      if (isGuest) {
                        showGuestActionDialog(
                          context,
                          title: 'Notification Settings',
                          message: 'Please log in to manage your notification settings.',
                        );
                        return;
                      }
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
              child: isGuest
                  ? _drawerItem(
                      context: context,
                      icon: Icons.login,
                      title: 'Sign In / Register',
                      iconColor: AppTheme.jeapPurple,
                      textColor: AppTheme.jeapPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    )
                  : _drawerItem(
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
    return ValueListenableBuilder<bool>(
      valueListenable: AuthSession.instance.isGuestNotifier,
      builder: (context, isGuest, _) {
        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: AuthSession.instance.userNotifier,
          builder: (context, user, _) {
            final name = AuthSession.instance.displayName;
            final email = isGuest ? 'Browsing without account' : AuthSession.instance.email;
            final isSeller = AuthSession.instance.isSeller;
            final avatarUrl = AuthSession.instance.avatarUrl;

            return InkWell(
              onTap: () {
                Navigator.pop(context);
                if (isGuest) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                }
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
                                isGuest
                                    ? Icons.explore_outlined
                                    : (isSeller
                                        ? Icons.store_outlined
                                        : Icons.verified_user_outlined),
                                size: 12,
                                color: AppTheme.jeapPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isGuest
                                    ? 'Guest'
                                    : (isSeller ? 'Seller' : 'Buyer'),
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
                        JeapAvatar(
                          radius: 22,
                          imageUrl: avatarUrl,
                          name: isGuest ? 'G' : name,
                          cacheBust: true,
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
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isGuest
                                      ? AppTheme.jeapPurple
                                      : AppTheme.textSecondary,
                                  fontWeight: isGuest
                                      ? FontWeight.w600
                                      : FontWeight.normal,
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
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 20, color: effectiveIconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: effectiveTextColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.jeapPurple,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
