import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/features/notifications/models/notification_item.dart';
import 'package:jeap_mobile/features/notifications/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  bool _isLoading = true;
  String? _error;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _service.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = res.notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    await _service.markAllAsRead();
    if (mounted) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(showWishlist: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_notifications.isNotEmpty)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: AppTheme.jeapPurple,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotifications,
                color: AppTheme.jeapPurple,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.jeapPurple),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.jeapPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 6),
          Center(
            child: Text(
              'We will notify you about your orders, updates, and deals here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return Container(
          color: item.read
              ? Colors.transparent
              : AppTheme.jeapPurple.withValues(alpha: 0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.jeapPurple.withValues(alpha: 0.12),
              child: Icon(
                _notificationIcon(item.type),
                color: AppTheme.jeapPurple,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: item.read ? FontWeight.w500 : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item.createdAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            onTap: () async {
              if (!item.read) {
                await _service.markAsRead(item.id);
                setState(() {
                  _notifications[index] = NotificationItem(
                    id: item.id,
                    type: item.type,
                    title: item.title,
                    message: item.message,
                    read: true,
                    createdAt: item.createdAt,
                    data: item.data,
                  );
                });
              }
            },
          ),
        );
      },
    );
  }

  IconData _notificationIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('order')) {
      return Icons.local_shipping_outlined;
    }
    if (lower.contains('promo') || lower.contains('voucher')) {
      return Icons.discount_outlined;
    }
    if (lower.contains('security') || lower.contains('password')) {
      return Icons.lock_outline;
    }
    if (lower.contains('message') || lower.contains('chat')) {
      return Icons.chat_bubble_outline;
    }
    return Icons.notifications_outlined;
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins <= 1 ? 'Just now' : '$mins mins ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    }
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
