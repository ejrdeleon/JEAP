import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/messaging/models/conversation.dart';

class BuyerChatScreen extends StatefulWidget {
  final Conversation conversation;
  const BuyerChatScreen({super.key, required this.conversation});

  @override
  State<BuyerChatScreen> createState() => _BuyerChatScreenState();
}

class _BuyerChatScreenState extends State<BuyerChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // TODO: replace with MessageService.fetchMessages() + sendMessage()
  final List<_LocalMessage> _messages = [
    _LocalMessage(
        text: 'Hello! How can I help you?',
        isMine: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 15))),
    _LocalMessage(
        text: 'When will my order be shipped?',
        isMine: true,
        sentAt: DateTime.now().subtract(const Duration(minutes: 10))),
    _LocalMessage(
        text: 'Your order is being prepared and will ship tomorrow.',
        isMine: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 8))),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages
          .add(_LocalMessage(text: text, isMine: true, sentAt: DateTime.now()));
    });
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: AppTheme.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.participantName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            Text(
              widget.conversation.participantRole[0].toUpperCase() +
                  widget.conversation.participantRole.substring(1),
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  return Align(
                    alignment: msg.isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isMine ? AppTheme.jeapPurple : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(msg.isMine ? 12 : 0),
                          bottomRight: Radius.circular(msg.isMine ? 0 : 12),
                        ),
                        border: msg.isMine
                            ? null
                            : Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(msg.text,
                              style: TextStyle(
                                  color: msg.isMine
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(msg.sentAt),
                            style: TextStyle(
                                fontSize: 10,
                                color: msg.isMine
                                    ? Colors.white70
                                    : AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: AppTheme.jeapPurple),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _LocalMessage {
  final String text;
  final bool isMine;
  final DateTime sentAt;
  _LocalMessage(
      {required this.text, required this.isMine, required this.sentAt});
}
