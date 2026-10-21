import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
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
  final _messageService = MessageService();
  bool _isLoading = true;
  String? _error;
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _messageService.fetchConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load messages. Please check your connection.';
          _isLoading = false;
        });
      }
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Messages',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadConversations,
                color: AppTheme.jeapPurple,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                onPressed: _loadConversations,
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

    if (_conversations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No messages yet',
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
              'When you message a seller, rider, or support, chats appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final conv = _conversations[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.jeapPurple.withValues(alpha: 0.15),
            child: Icon(
              _roleIcon(conv.participantRole),
              color: AppTheme.jeapPurple,
              size: 20,
            ),
          ),
          title: Text(
            conv.participantName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            conv.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (conv.lastMessageAt != null)
                Text(
                  _formatTime(conv.lastMessageAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              if (conv.unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppTheme.jeapPurple,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${conv.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuyerChatScreen(conversation: conv),
              ),
            );
            _loadConversations();
          },
        );
      },
    );
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'seller':
        return Icons.store_outlined;
      case 'rider':
      case 'courier':
        return Icons.delivery_dining_outlined;
      case 'admin':
      case 'super-admin':
        return Icons.verified_user_outlined;
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
