import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/notifications/models/notification_item.dart';

class NotificationResult {
  final int unreadCount;
  final List<NotificationItem> notifications;

  const NotificationResult({
    required this.unreadCount,
    required this.notifications,
  });
}

class NotificationService {
  final ApiClient _api;

  NotificationService({ApiClient? api}) : _api = api ?? const ApiClient();

  Future<NotificationResult> fetchNotifications() async {
    try {
      final res = await _api.get('/notifications');
      if (res is Map) {
        final unread = (res['unread_count'] as num?)?.toInt() ?? 0;
        final list = (res['notifications'] as List? ?? [])
            .whereType<Map>()
            .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return NotificationResult(unreadCount: unread, notifications: list);
      }
      return const NotificationResult(unreadCount: 0, notifications: []);
    } catch (_) {
      return const NotificationResult(unreadCount: 0, notifications: []);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.post('/notifications/$id/read', {});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all', {});
    } catch (_) {}
  }
}
