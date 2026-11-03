import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/core/widgets/guest_prompt_view.dart';
import 'package:jeap_mobile/core/widgets/jeap_app_bar.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';
import 'package:jeap_mobile/features/messaging/presentation/screens/buyer_chat_screen.dart';
import 'package:jeap_mobile/features/messaging/services/message_service.dart';

class BuyerConversationsScreen extends StatefulWidget {
  const BuyerConversationsScreen({super.key});

  @override
  State<BuyerConversationsScreen> createState() =>
      _BuyerConversationsScreenState();
}

class _BuyerConversationsScreenState extends State<BuyerConversationsScreen> {
  final MessageService _service = MessageService();
  List<Conversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthSession.instance.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load messages. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.instance.isAuthenticated) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: JeapAppBar(showWishlist: false),
        body: SafeArea(
          child: GuestPromptView(
            title: 'Sign in to message',
            message: 'Log in or sign up to chat with sellers and JEAP Dash riders about your orders.',
            icon: Icons.chat_bubble_outline,
          ),
        ),
      );
    }

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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.jeapPurple),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                TextButton(onPressed: _load, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : _conversations.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No messages yet. Chat starts from an order after checkout.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppTheme.jeapPurple,
                              child: ListView.separated(
                                itemCount: _conversations.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 72),
                                itemBuilder: (_, i) {
                                  final conv = _conversations[i];
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
                                        builder: (_) =>
                                            BuyerChatScreen(conversation: conv),
                                      ),
                                    ).then((_) => _load()),
                                  );
                                },
                              ),
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
      case 'courier':
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
