import 'package:flutter/material.dart';
import 'package:jeap_mobile/core/theme/app_theme.dart';

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
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.jeapPurple),
                    label: Text(_quickReplies[index],
                        style: const TextStyle(
                            color: AppTheme.jeapPurple, fontSize: 12)),
                    onPressed: () => _sendMessage(_quickReplies[index]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message to buyer...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
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
