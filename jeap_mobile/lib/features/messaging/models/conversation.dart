class Conversation {
  final int id;
  final String participantName;
  final String participantRole; // seller | rider | admin
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantRole,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List? ?? [])
        .whereType<Map>()
        .map((participant) => Map<String, dynamic>.from(participant))
        .toList();
    final lastMessage = json['last_message'];
    final participantName = participants.isNotEmpty
        ? participants.first['name']?.toString()
        : json['participant_name']?.toString();
    final messageBody = lastMessage is Map
        ? lastMessage['body']?.toString()
        : lastMessage?.toString();
    final sentAt =
        lastMessage is Map ? lastMessage['sent_at'] : json['last_message_at'];

    return Conversation(
      id: (json['id'] as num).toInt(),
      participantName: participantName ?? 'JEAP user',
      participantRole: json['participant_role']?.toString() ?? 'contact',
      lastMessage: messageBody,
      lastMessageAt: sentAt is String ? DateTime.tryParse(sentAt) : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final String text;
  final bool isMine;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, int myUserId) =>
      ChatMessage(
        id: (json['id'] as num).toInt(),
        text: (json['body'] ?? json['message'] ?? '').toString(),
        isMine: json['is_mine'] is bool
            ? json['is_mine'] as bool
            : (json['user_id'] ?? json['sender_id']) == myUserId,
        sentAt: DateTime.tryParse(
              (json['created_at'] ?? json['sent_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
      );
}
