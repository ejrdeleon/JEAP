import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_chat_screen.dart';

class BuyerConversationsScreen extends StatelessWidget {
  const BuyerConversationsScreen({super.key});

  // TODO: replace with MessageService.fetchConversations()
  static final _mockConversations = [
    Conversation(
      id: 1,
      participantName: 'TechStore PH',
      participantRole: 'seller',
      lastMessage: 'Your order is being prepared.',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 10)),
      unreadCount: 1,
    ),
    Conversation(
      id: 2,
      participantName: 'Rider: Juan D.',
      participantRole: 'rider',
      lastMessage: 'I am on my way to your address.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Conversation(
      id: 3,
      participantName: 'JEAP Support',
      participantRole: 'admin',
      lastMessage: 'How can we help you today?',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const JeapAppBar(showWishlist: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Messages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _mockConversations.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final conv = _mockConversations[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.jeapPurple.withValues(alpha: 0.15),
                      child: Icon(
                        _roleIcon(conv.participantRole),
                        color: AppTheme.jeapPurple,
                        size: 20,
                      ),
                    ),
                    title: Text(conv.participantName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      conv.lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (conv.lastMessageAt != null)
                          Text(
                            _formatTime(conv.lastMessageAt!),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        if (conv.unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppTheme.jeapPurple,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('${conv.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuyerChatScreen(conversation: conv),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'seller':
        return Icons.store_outlined;
      case 'rider':
        return Icons.delivery_dining_outlined;
      default:
        return Icons.support_agent_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}';
  }
}
