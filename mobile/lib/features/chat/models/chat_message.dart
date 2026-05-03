enum MessageType { user, ai, expert, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  String get timeFormatted =>
      '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
}
