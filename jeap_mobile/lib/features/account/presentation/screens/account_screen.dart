import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/core/widgets/jeap_avatar.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/buyer/presentation/widgets/buyer_drawer.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/manage_addresses_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';

class AccountScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUser;
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onSelectTab;

  const AccountScreen({
    super.key,
    this.initialUser,
    this.onOpenDrawer,
    this.onSelectTab,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = AuthService();
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = widget.initialUser != null
        ? Future.value(widget.initialUser)
        : (AuthSession.instance.currentUser != null
            ? Future.value(AuthSession.instance.currentUser)
            : _authService.me());
  }

  void _refresh() {
    setState(() {
      _userFuture = _authService.me();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AuthSession.instance.isGuest) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        drawer: BuyerDrawer(currentTabIndex: 4, onSelectTab: widget.onSelectTab),
        appBar: JeapAppBar(showBack: false, showWishlist: false, onMenuTap: widget.onOpenDrawer),
        body: const SafeArea(
          child: GuestPromptView(
            title: 'Your Account',
            message:
                'Sign in to your JEAP account to manage your profile, delivery addresses, security settings, and order history.',
            icon: Icons.person_outline,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: BuyerDrawer(currentTabIndex: 4, onSelectTab: widget.onSelectTab),
      appBar: JeapAppBar(showBack: false, showWishlist: false, onMenuTap: widget.onOpenDrawer),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header reactive to userNotifier
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: AuthSession.instance.userNotifier,
                builder: (context, activeUser, _) {
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _userFuture,
                    builder: (context, snapshot) {
                      final user = activeUser ?? snapshot.data ?? AuthSession.instance.currentUser;
                      final String name = (user?['name'] as String?) ??
                          (user?['first_name'] != null
                              ? '${user?['first_name']} ${user?['last_name'] ?? ''}'
                                  .trim()
                              : 'Juan Dela Cruz');
                      final String email =
                          (user?['email'] as String?) ?? 'juan@example.com';
                      final String role = (user?['role'] as String?) ?? 'buyer';
                      final String status = role.isNotEmpty
                          ? role[0].toUpperCase() + role.substring(1)
                          : 'Active';

                      return Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Row(
                          children: [
                            JeapAvatar(
                              radius: 32,
                              imageUrl: user?['avatar_url'] ?? AuthSession.instance.avatarUrl,
                              name: name,
                              cacheBust: true,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(email,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(status,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.statusGreen,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Menu sections
              _MenuSection(title: 'Account', items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    );
                    _refresh();
                  },
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Manage Addresses',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ManageAddressesScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              _MenuSection(title: 'Support', items: [
                _MenuItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messages',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BuyerConversationsScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 8),

              _MenuSection(title: '', items: [
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.red,
                  onTap: () => _confirmLogout(context),
                ),
              ]),
              const SizedBox(height: 24),
            ],
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
              await _authService.logout();
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

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5)),
            ),
          ...items.map((item) => ListTile(
                leading: Icon(item.icon,
                    color: item.color ?? AppTheme.textPrimary, size: 22),
                title: Text(item.label,
                    style: TextStyle(
                        fontSize: 14,
                        color: item.color ?? AppTheme.textPrimary)),
                trailing: const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 20),
                onTap: item.onTap,
              )),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}
