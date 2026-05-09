enum MessageType { user, ai, expert, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Added for rich action cards

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.createdAt,
    this.metadata,
  });

  String get timeFormatted =>
      '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
}
