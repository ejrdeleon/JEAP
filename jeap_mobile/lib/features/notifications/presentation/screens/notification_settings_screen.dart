import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _api = const ApiClient();

  bool _loading = true;
  bool _orderUpdates = true;
  bool _chatMessages = true;
  bool _promotions = true;
  bool _sound = true;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!AuthSession.instance.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await _api.get('/notification-preferences');
      final prefs = res is Map ? res['preferences'] as Map? : null;
      if (prefs != null && mounted) {
        setState(() {
          _orderUpdates = prefs['order_updates'] == true;
          _chatMessages = prefs['chat'] == true;
          _promotions = prefs['promos'] == true;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      await _api.put('/notification-preferences', {
        'order_updates': _orderUpdates,
        'chat': _chatMessages,
        'promos': _promotions,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notification preferences. Try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _onToggle(String key, bool val) {
    setState(() {
      switch (key) {
        case 'order_updates':
          _orderUpdates = val;
          break;
        case 'chat_messages':
          _chatMessages = val;
          break;
        case 'promotions':
          _promotions = val;
          break;
        case 'sound':
          _sound = val;
          break;
        case 'vibration':
          _vibration = val;
          break;
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isRider = AuthSession.instance.isRider;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  const Text(
                    'Notification Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'These match the same order, chat, and promo settings as the website.',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _sectionHeader(isRider ? 'Assignments & orders' : 'Order & Tracking Updates'),
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.local_shipping_outlined,
                      title: isRider
                          ? 'Assignment and order updates'
                          : 'Order Tracking & Delivery',
                      subtitle: isRider
                          ? 'Get updates when a pickup or delivery is assigned to you.'
                          : 'Get updates when your order is packed, out for delivery, and delivered.',
                      value: _orderUpdates,
                      onChanged: (v) => _onToggle('order_updates', v),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionHeader('Messages & Communication'),
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Direct Messages & Chat',
                      subtitle:
                          'Instant alerts when sellers, riders, or buyers send you a chat message.',
                      value: _chatMessages,
                      onChanged: (v) => _onToggle('chat_messages', v),
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.campaign_outlined,
                      title: 'Promotions & Announcements',
                      subtitle:
                          'Receive news about sales, store discounts, and service announcements.',
                      value: _promotions,
                      onChanged: (v) => _onToggle('promotions', v),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionHeader('Sound & Haptics'),
                  _buildCard([
                    _buildSwitchTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Sound Notification',
                      subtitle:
                          'Play alert sounds when receiving notifications.',
                      value: _sound,
                      onChanged: (v) => _onToggle('sound', v),
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.vibration_outlined,
                      title: 'Vibration',
                      subtitle:
                          'Vibrate for incoming notifications and alerts.',
                      value: _vibration,
                      onChanged: (v) => _onToggle('vibration', v),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.jeapPurple,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.buyerRadius),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      activeThumbColor: AppTheme.jeapPurple,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      secondary: Icon(icon, color: AppTheme.jeapPurple, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
