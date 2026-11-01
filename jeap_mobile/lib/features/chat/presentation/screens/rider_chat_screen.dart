import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';
import 'package:jeap_mobile/features/tasks/presentation/screens/rider_home_screen.dart';

class ChatMessage {
  final String text;
  final bool isRider;
  final DateTime timestamp;

  ChatMessage(
      {required this.text, required this.isRider, required this.timestamp});
}

class RiderChatScreen extends StatefulWidget {
  final String buyerName;
  final String trackingNumber;

  const RiderChatScreen({
    super.key,
    required this.buyerName,
    required this.trackingNumber,
  });

  @override
  State<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends State<RiderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  final List<String> _quickReplies = [
    "I am approaching your address.",
    "Please prepare exact COD amount.",
    "I am leaving your parcel at the front door/guard.",
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.insert(
        0,
        ChatMessage(text: text, isRider: true, timestamp: DateTime.now()),
      );
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
                (_) => false,
              );
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.buyerName, style: const TextStyle(fontSize: 16)),
            Text('Parcel: ${widget.trackingNumber}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isRider
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isRider ? AppTheme.jeapPurple : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: msg.isRider
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                          color: msg.isRider
                              ? Colors.white
                              : AppTheme.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(_quickReplies[index],
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(_quickReplies[index]),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.jeapPurple),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
