enum MessageType { user, ai, expert, system }

enum MessageContentType { text, audio, file }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final MessageContentType contentType;
  final String? mediaUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    this.contentType = MessageContentType.text,
    this.mediaUrl,
    required this.createdAt,
    this.metadata,
    this.isDeleted = false,
  });

  String get timeFormatted =>
      '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageType? type,
    MessageContentType? contentType,
    String? mediaUrl,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        text: text ?? this.text,
        type: type ?? this.type,
        contentType: contentType ?? this.contentType,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        createdAt: createdAt ?? this.createdAt,
        metadata: metadata ?? this.metadata,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
