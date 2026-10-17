import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';

class MessageService {
  final ApiClient _api;

  MessageService({ApiClient? client}) : _api = client ?? const ApiClient();

  Future<List<Conversation>> fetchConversations() async {
    final res = await _api.get('/conversations');
    final list = res is List
        ? res
        : (res is Map ? res['conversations'] ?? res['data'] ?? [] : []) as List;
    return list
        .whereType<Map>()
        .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(
      int conversationId, int myUserId) async {
    final res = await _api.get('/conversations/$conversationId/messages');
    final list = res is List
        ? res
        : (res is Map ? res['messages'] ?? res['data'] ?? [] : []) as List;
    return list
        .whereType<Map>()
        .map(
            (e) => ChatMessage.fromJson(Map<String, dynamic>.from(e), myUserId))
        .toList();
  }

  Future<void> sendMessage(int conversationId, String message) => _api
      .post('/conversations/$conversationId/messages', {'message': message});

  Future<int> startConversation(String orderNumber, String message) async {
    final res = await _api.post('/conversations', {
      'order_number': orderNumber,
      'message': message,
    });
    return (res is Map ? res['conversation_id'] as int? : null) ?? 0;
  }
}
