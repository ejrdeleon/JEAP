import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const _storageKey = 'jeap_notification_preferences';
  static const _storage = FlutterSecureStorage();

  bool _loading = true;
  bool _orderUpdates = true;
  bool _taskAssignments = true;
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
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          setState(() {
            _orderUpdates = data['order_updates'] ?? true;
            _taskAssignments = data['task_assignments'] ?? true;
            _chatMessages = data['chat_messages'] ?? true;
            _promotions = data['promotions'] ?? true;
            _sound = data['sound'] ?? true;
            _vibration = data['vibration'] ?? true;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    try {
      final map = {
        'order_updates': _orderUpdates,
        'task_assignments': _taskAssignments,
        'chat_messages': _chatMessages,
        'promotions': _promotions,
        'sound': _sound,
        'vibration': _vibration,
      };
      await _storage.write(key: _storageKey, value: jsonEncode(map));
    } catch (_) {}
  }

  void _onToggle(String key, bool val) {
    setState(() {
      switch (key) {
        case 'order_updates':
          _orderUpdates = val;
          break;
        case 'task_assignments':
          _taskAssignments = val;
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
                    'Configure push notifications, sound alerts, and update preferences.',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (isRider) ...[
                    _sectionHeader('Rider & Delivery Alerts'),
                    _buildCard([
                      _buildSwitchTile(
                        icon: Icons.two_wheeler_outlined,
                        title: 'New Delivery Assignments',
                        subtitle:
                            'Get instant alerts when a pickup or delivery task is assigned to you.',
                        value: _taskAssignments,
                        onChanged: (v) => _onToggle('task_assignments', v),
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        icon: Icons.local_shipping_outlined,
                        title: 'Assignment Status Changes',
                        subtitle:
                            'Receive status updates on package pickups, handoffs, and verification.',
                        value: _orderUpdates,
                        onChanged: (v) => _onToggle('order_updates', v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ] else ...[
                    _sectionHeader('Order & Tracking Updates'),
                    _buildCard([
                      _buildSwitchTile(
                        icon: Icons.local_shipping_outlined,
                        title: 'Order Tracking & Delivery',
                        subtitle:
                            'Receive real-time notifications when your order is packed, dispatched, and out for delivery.',
                        value: _orderUpdates,
                        onChanged: (v) => _onToggle('order_updates', v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],
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
