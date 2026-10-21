class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.createdAt,
    this.data = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'])
          : const {},
    );
  }
}
