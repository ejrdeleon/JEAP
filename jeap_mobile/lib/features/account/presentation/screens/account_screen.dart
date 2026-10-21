import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/features/auth/services/auth_service.dart';
import 'package:jeap_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_conversations_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/edit_profile_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/manage_addresses_screen.dart';
import 'package:jeap_mobile/features/account/presentation/screens/change_password_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = AuthService();
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.me();
  }

  void _refresh() {
    setState(() {
      _userFuture = _authService.me();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(showBack: false, showWishlist: false),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header via FutureBuilder
              FutureBuilder<Map<String, dynamic>?>(
                future: _userFuture,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final String name = (user?['name'] as String?) ??
                      (user?['first_name'] != null
                          ? '${user?['first_name']} ${user?['last_name'] ?? ''}'
                              .trim()
                          : 'Juan Dela Cruz');
                  final String email =
                      (user?['email'] as String?) ?? 'juan@example.com';
                  final roles = user?['roles'] as List?;
                  final bool isSeller = user?['is_seller'] == true ||
                      (roles != null && roles.contains('seller')) ||
                      user?['role'] == 'seller';

                  final initials = name.trim().isNotEmpty
                      ? name
                          .trim()
                          .split(' ')
                          .where((p) => p.isNotEmpty)
                          .take(2)
                          .map((e) => e[0].toUpperCase())
                          .join()
                      : 'JD';

                  return Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              AppTheme.jeapPurple.withValues(alpha: 0.15),
                          child: snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  user == null
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(initials,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.jeapPurple)),
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
                              if (isSeller) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.jeapPurple
                                        .withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: AppTheme.jeapPurple
                                          .withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.store_outlined,
                                          size: 12, color: AppTheme.jeapPurple),
                                      SizedBox(width: 4),
                                      Text(
                                        'Seller',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.jeapPurple,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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
    return Container(
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
