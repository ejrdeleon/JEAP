import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';

class MessageService {
  final ApiClient _api;

  MessageService({ApiClient? client}) : _api = client ?? const ApiClient();

  Future<List<Conversation>> fetchConversations() async {
    final res = await _api.get('/conversations') as List;
    return res
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(
      int conversationId, int myUserId) async {
    final res =
        await _api.get('/conversations/$conversationId/messages') as List;
    return res
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, myUserId))
        .toList();
  }

  Future<void> sendMessage(int conversationId, String message) => _api
      .post('/conversations/$conversationId/messages', {'message': message});
}
