import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/reverb_service.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI Mock Responses (for IA Nexora chat — no backend conversation needed)
// ─────────────────────────────────────────────────────────────────────────────

const _kAiResponses = [
  {
    'text': 'Bonjour ! Je suis l\'IA Nexora. Comment puis-je vous aider aujourd\'hui ?',
  },
  {
    'text': 'Je comprends. Pouvez-vous me donner plus de détails sur vos symptômes ?',
  },
  {
    'text': 'Merci pour ces précisions. D\'après mon analyse, je vous recommande vivement de consulter un spécialiste pour ce problème.',
    'metadata': {
      'type': 'expert_recommendation',
      'expert': {
        'id': 1,
        'name': 'Dr. Amina Berrada',
        'specialty': 'Pédiatre',
        'rating': 4.9,
        'hourlyRate': 250,
      }
    }
  },
  {
    'text': 'C\'est noté. Depuis combien de temps ressentez-vous cela ?',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isLoading;
  final String? error;
  /// Live online status of the OTHER participant (updated via WebSocket)
  final bool? isOtherOnline;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isLoading = false,
    this.error,
    this.isOtherOnline,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isLoading,
    String? error,
    bool? isOtherOnline,
    bool clearOtherOnline = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isOtherOnline: clearOtherOnline ? null : (isOtherOnline ?? this.isOtherOnline),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends AutoDisposeNotifier<ChatState> {
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  bool _disposed = false;
  bool _isAi = true;
  int? _conversationId;
  int? _viewerUserId; // current logged-in user — used to filter own WS events

  @override
  ChatState build() {
    ref.onDispose(() {
      _disposed = true;
      _wsSub?.cancel();
      if (_conversationId != null) {
        ref.read(reverbServiceProvider).unsubscribe(_conversationId!);
      }
    });
    return const ChatState(messages: []);
  }

  // ── Called by ChatScreen on open ─────────────────────────────────────────

  void initialize({required bool isAi, int? conversationId, bool? otherOnline}) {
    _isAi = isAi;
    // Resolve the current user ID so we can filter out our own WS events
    _viewerUserId = ref.read(currentUserProvider).valueOrNull?.id;
    // Seed the live online state from the navigation argument
    if (otherOnline != null) {
      state = state.copyWith(isOtherOnline: otherOnline);
    }

    if (conversationId != null) {
      _conversationId = conversationId;
      _loadMessagesFromBackend(conversationId);
      _startWebSocket(conversationId);
    } else if (isAi) {
      // IA Nexora chat — show welcome message, no backend
      state = state.copyWith(
        messages: [
          ChatMessage(
            id: 'ai_welcome',
            text: _kAiResponses[0]['text'] as String,
            type: MessageType.ai,
            createdAt: DateTime.now(),
          ),
        ],
      );
    }
  }

  Future<void> _loadMessagesFromBackend(int conversationId) async {
    if (!_disposed) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/conversations/$conversationId/messages');
      final data = response.data as Map<String, dynamic>;
      final messagesData = data['data'] as List<dynamic>? ?? [];

      final messages = messagesData.map((msg) {
        final msgMap = msg as Map<String, dynamic>;
        final senderType = msgMap['sender_type'] as String? ?? 'ai';
        final type = senderType == 'user'
            ? MessageType.user
            : senderType == 'expert'
                ? MessageType.expert
                : MessageType.ai;
        final isAudio = (msgMap['type'] as String?) == 'audio';
        final rawUrl = msgMap['media_url'] as String?;

        return ChatMessage(
          id: msgMap['id']?.toString() ?? '',
          text: msgMap['content'] as String? ?? '',
          type: type,
          contentType: isAudio ? MessageContentType.audio : MessageContentType.text,
          mediaUrl: rawUrl != null ? fixStorageUrl(rawUrl) : null,
          createdAt: msgMap['created_at'] is String
              ? DateTime.tryParse(msgMap['created_at'] as String) ??
                  DateTime.now()
              : DateTime.now(),
        );
      }).toList();

      if (!_disposed) {
        state = state.copyWith(messages: messages, isLoading: false);
      }

      // Mark all messages as read so the unread badge clears in the conversations list
      _markAllRead(conversationId);
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Erreur: $e',
          messages: [],
        );
      }
    }
  }

  /// Calls PUT /conversations/{id}/messages/read-all — fire and forget.
  Future<void> _markAllRead(int conversationId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/conversations/$conversationId/messages/read-all');
    } catch (_) {
      // Non-critical — ignore failures silently
    }
  }

  // ── WebSocket subscription via Reverb ────────────────────────────────────

  Future<void> _startWebSocket(int conversationId) async {
    final stream = await ref
        .read(reverbServiceProvider)
        .subscribePrivate(conversationId);

    _wsSub = stream.listen((event) {
      final eventType = event['event'] as String?;
      final payload   = event['payload'] as Map<String, dynamic>? ?? {};

      // typing event: 'is_typing' key (matches UserTyping.broadcastWith)
      if (eventType == 'typing') {
        final isTypingEvent = payload['is_typing'] as bool? ?? false;
        final typingUserId  = payload['user_id'] as int?;
        // Don't show indicator for own typing events
        if (typingUserId != null && typingUserId == _viewerUserId) return;
        setTyping(isTypingEvent);
        return;
      }

      // MessageDeleted — mark message as deleted (WhatsApp-style placeholder)
      if (eventType == 'message.deleted') {
        final deletedId = payload['message_id']?.toString() ?? '';
        if (deletedId.isNotEmpty) _markDeleted(deletedId);
        return;
      }

      // UserPresenceChanged — update the other participant's online dot instantly
      if (eventType == 'user.presence') {
        final presenceUserId = payload['user_id'] as int?;
        // Only handle presence events from the OTHER participant
        if (presenceUserId != null && presenceUserId != _viewerUserId) {
          final isOnline = payload['is_online'] as bool? ?? false;
          if (!_disposed) state = state.copyWith(isOtherOnline: isOnline);
        }
        return;
      }

      // message.sent or ai.response — extract message object
      // Both events use broadcastWith: { 'message': MessageResource }
      final msgData    = payload['message'] as Map<String, dynamic>? ?? payload;
      final senderType = msgData['sender_type'] as String? ?? 'ai';
      final senderId   = msgData['sender_id'] as int?;
      final msgId      = msgData['id']?.toString() ?? '';
      final isAudio    = (msgData['type'] as String?) == 'audio';
      final rawUrl     = msgData['media_url'] as String?;
      final content    = msgData['content'] as String? ?? '';

      // Own audio confirmed by server — upgrade local temp path → S3 URL
      // Only for viewer's own audio messages
      if (senderId != null && senderId == _viewerUserId && isAudio && rawUrl != null) {
        if (_disposed) return;
        final s3Url = fixStorageUrl(rawUrl);
        state = state.copyWith(
          messages: state.messages.map((m) {
            // Find the local temp bubble: user audio with a local file path
            if (m.contentType == MessageContentType.audio &&
                m.type == MessageType.user &&
                m.mediaUrl != null &&
                !m.mediaUrl!.startsWith('http')) {
              return m.copyWith(
                id: msgId.isNotEmpty ? msgId : m.id,
                mediaUrl: s3Url,
              );
            }
            return m;
          }).toList(),
        );
        return;
      }

      // Skip own text messages — already added optimistically
      // Use sender_id to correctly identify own messages regardless of role
      if (senderId != null && senderId == _viewerUserId) return;

      if (!isAudio && content.isEmpty) return;
      if (state.messages.any((m) => m.id == msgId)) return;

      final type = senderType == 'expert'
          ? MessageType.expert
          : senderType == 'user'
              ? MessageType.user
              : MessageType.ai;

      if (_disposed) return;
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: msgId,
            text: content,
            type: type,
            contentType: isAudio ? MessageContentType.audio : MessageContentType.text,
            mediaUrl: rawUrl != null ? fixStorageUrl(rawUrl) : null,
            createdAt: DateTime.now(),
          ),
        ],
        isTyping: false,
      );

      // Auto-read new incoming messages while the chat is open
      if (_conversationId != null) _markAllRead(_conversationId!);
    });
  }

  // ── Called by ChatScreen when user submits a message ─────────────────────

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(
      messages: [...state.messages, _build(trimmed, MessageType.user)],
    );

    if (_conversationId != null) {
      _postMessage(trimmed);
    } else if (_isAi) {
      _aiMockResponse();
    }
  }

  Future<void> _postMessage(String text) async {
    if (_conversationId == null) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/conversations/$_conversationId/messages',
        data: {'content': text},
      );
    } catch (e) {
      // Error posting message - message already appears optimistically
    }
  }

  Future<void> _aiMockResponse() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_disposed) return;

    setTyping(true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (_disposed) return;

    final step = state.messages.length ~/ 2; 
    final replyIndex = step % _kAiResponses.length;
    final replyData = _kAiResponses[replyIndex];
    
    receiveMessage(
      replyData['text'] as String, 
      MessageType.ai,
      metadata: replyData['metadata'] as Map<String, dynamic>?,
    );
  }

  // ── Called by ChatScreen after audio recording is done ───────────────────

  Future<void> sendAudioMessage(String filePath, {int durationSeconds = 0}) async {
    if (_disposed) return;

    // Optimistic local bubble — visible immediately, kept even on upload failure
    final tempId = 'local_audio_${DateTime.now().microsecondsSinceEpoch}';
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          id: tempId,
          text: '',
          type: MessageType.user,
          contentType: MessageContentType.audio,
          mediaUrl: filePath,
          createdAt: DateTime.now(),
          metadata: durationSeconds > 0
              ? {'duration_seconds': durationSeconds}
              : null,
        ),
      ],
    );

    // AI demo mode — no backend, reply with mock text response
    if (_conversationId == null) {
      if (_isAi) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (_disposed) return;
        setTyping(true);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (_disposed) return;
        receiveMessage(
          'J\'ai bien reçu votre message vocal. Pouvez-vous me décrire vos symptômes par écrit pour que je puisse mieux vous aider ?',
          MessageType.ai,
        );
      }
      return;
    }

    // Real backend upload — keep bubble visible even on failure
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          filename: 'audio.m4a',
          contentType: DioMediaType('audio', 'm4a'),
        ),
      });
      await dio.post(
        '/conversations/$_conversationId/messages/audio',
        data: formData,
      );
    } catch (e) {
      debugPrint('[Audio] Upload failed: $e');
      // Bubble stays — user can still play the local recording
    }
  }

  // ── Called by WebSocket layer when a message arrives ─────────────────────

  void receiveMessage(String text, MessageType type, {Map<String, dynamic>? metadata}) {
    if (_disposed) return;
    state = state.copyWith(
      messages: [...state.messages, _build(text, type, metadata: metadata)],
      isTyping: false,
    );
  }

  // ── Called by WebSocket layer on typing events ────────────────────────────

  void setTyping(bool value) {
    if (_disposed) return;
    state = state.copyWith(isTyping: value);
  }

  // ── Send typing event to backend (called from input onChange) ────────────

  bool _lastIsTyping = false;

  Future<void> sendTyping({required bool isTyping}) async {
    if (_conversationId == null) return;
    if (_lastIsTyping == isTyping) return; // avoid duplicate API calls
    _lastIsTyping = isTyping;
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/conversations/$_conversationId/typing',
        data: {'is_typing': isTyping},
      );
    } catch (_) {
      // Non-critical — silently ignore
    }
  }

  // ── Message deletion ─────────────────────────────────────────────────────

  /// Soft-delete for everyone: calls API + server broadcasts to all participants.
  Future<void> deleteMessage(String messageId) async {
    if (_conversationId == null) return;

    // Optimistic update — show placeholder immediately
    _markDeleted(messageId);

    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/conversations/$_conversationId/messages/$messageId');
    } catch (e) {
      debugPrint('[Chat] deleteMessage failed: $e');
      // Revert optimistic update
      _unmarkDeleted(messageId);
    }
  }

  /// Delete only on this device — no API call, no broadcast.
  void deleteForMe(String messageId) {
    _markDeleted(messageId);
  }

  void _markDeleted(String messageId) {
    if (_disposed) return;
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) return m.copyWith(isDeleted: true);
        return m;
      }).toList(),
    );
  }

  void _unmarkDeleted(String messageId) {
    if (_disposed) return;
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) return m.copyWith(isDeleted: false);
        return m;
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ChatMessage _build(String text, MessageType type, {Map<String, dynamic>? metadata}) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        type: type,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final chatProvider =
    AutoDisposeNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
