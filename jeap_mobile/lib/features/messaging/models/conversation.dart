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

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        participantName: json['participant_name'] as String,
        participantRole: json['participant_role'] as String,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        unreadCount: json['unread_count'] as int? ?? 0,
      );
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
        id: json['id'] as int,
        text: json['message'] as String,
        isMine: (json['sender_id'] as int) == myUserId,
        sentAt: DateTime.parse(json['created_at'] as String),
      );
}
