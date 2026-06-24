import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/reverb_service.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/chat_message.dart';
import 'conversations_provider.dart';

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
  /// Set when escalation fails with 402 — contains reason: 'no_plan' | 'no_credits'
  final String? escalate402Reason;
  /// True while escalation API call is in flight
  final bool isEscalating;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isLoading = false,
    this.error,
    this.isOtherOnline,
    this.escalate402Reason,
    this.isEscalating = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isLoading,
    String? error,
    bool? isOtherOnline,
    bool clearOtherOnline = false,
    String? escalate402Reason,
    bool clearEscalate402 = false,
    bool? isEscalating,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isOtherOnline: clearOtherOnline ? null : (isOtherOnline ?? this.isOtherOnline),
        escalate402Reason: clearEscalate402 ? null : (escalate402Reason ?? this.escalate402Reason),
        isEscalating: isEscalating ?? this.isEscalating,
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
  final _receivedMsgIds = <String>{}; // dedup guard — prevents double-add from MessageSent + AIResponseReady
  final _optimisticUserMessages = <String>{}; // temp IDs of messages sent from THIS device

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
    }
    // else isAi && no conversationId → empty state; suggestions shown in UI
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
        final msgType = (msgMap['type'] as String?) ?? 'text';
        final isAudio = msgType == 'audio';
        final isFile  = msgType == 'file';
        // Prefer audio_url (full MinIO URL) over media_url (raw S3 path)
        final rawUrl = (msgMap['audio_url'] as String?) ?? (msgMap['media_url'] as String?);
        final metadataRaw = msgMap['metadata'];
        final metadata = metadataRaw is Map
            ? Map<String, dynamic>.from(metadataRaw)
            : null;

        return ChatMessage(
          id: msgMap['id']?.toString() ?? '',
          text: msgMap['content'] as String? ?? '',
          type: type,
          contentType: isAudio
              ? MessageContentType.audio
              : isFile
                  ? MessageContentType.file
                  : MessageContentType.text,
          mediaUrl: rawUrl != null ? fixStorageUrl(rawUrl) : null,
          createdAt: msgMap['created_at'] is String
              ? DateTime.tryParse(msgMap['created_at'] as String) ??
                  DateTime.now()
              : DateTime.now(),
          metadata: metadata,
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
      final wsType     = (msgData['type'] as String?) ?? 'text';
      final isAudio    = wsType == 'audio';
      final isFile     = wsType == 'file';
      // Prefer audio_url (full MinIO URL) over media_url (raw S3 path)
      final rawUrl     = (msgData['audio_url'] as String?) ?? (msgData['media_url'] as String?);
      final content    = msgData['content'] as String? ?? '';
      final metadataRaw = msgData['metadata'];
      final metadata = metadataRaw is Map
          ? Map<String, dynamic>.from(metadataRaw)
          : null;

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

      // Own messages: distinguish this-device echo (already optimistic) from
      // another-device send (must be shown for cross-platform continuity).
      if (senderId != null && senderId == _viewerUserId) {
        // Find the optimistic bubble from this device with matching content
        final matchIndex = state.messages.lastIndexWhere((m) =>
          m.type == MessageType.user &&
          m.text == content &&
          _optimisticUserMessages.contains(m.id),
        );
        if (matchIndex >= 0) {
          // Echo of our own send — update temp ID to real server ID and stop
          if (msgId.isNotEmpty) {
            final tempId = state.messages[matchIndex].id;
            _optimisticUserMessages.remove(tempId);
            _receivedMsgIds.add(msgId);
            final updated = List<ChatMessage>.from(state.messages);
            updated[matchIndex] = updated[matchIndex].copyWith(id: msgId);
            if (!_disposed) state = state.copyWith(messages: updated);
          }
          return;
        }
        // No matching optimistic bubble → sent from another device/session, fall through
      }

      if (!isAudio && content.isEmpty) return;
      if (msgId.isNotEmpty && _receivedMsgIds.contains(msgId)) return;
      if (msgId.isNotEmpty) _receivedMsgIds.add(msgId);

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
            contentType: isAudio
                ? MessageContentType.audio
                : isFile
                    ? MessageContentType.file
                    : MessageContentType.text,
            mediaUrl: rawUrl != null ? fixStorageUrl(rawUrl) : null,
            createdAt: DateTime.now(),
            metadata: metadata,
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

    final msg = _build(trimmed, MessageType.user);
    _optimisticUserMessages.add(msg.id); // track so WS echo from this device is identified

    state = state.copyWith(
      messages: [...state.messages, msg],
      // Show typing indicator while waiting for AI/doctor response
      isTyping: _conversationId != null,
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
      // POST failed — clear typing indicator so dots don't spin forever
      if (!_disposed) state = state.copyWith(isTyping: false);
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

    // Real backend upload
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          filename: 'audio.m4a',
          contentType: DioMediaType('audio', 'mp4'), // M4A MIME type is audio/mp4
        ),
      });
      final response = await dio.post(
        '/conversations/$_conversationId/messages/audio',
        data: formData,
      );
      // Replace temp bubble with real message (has audio_url from S3)
      final real = response.data?['data'] as Map<String, dynamic>?;
      if (real != null && !_disposed) {
        final rawUrl = (real['audio_url'] as String?) ?? (real['media_url'] as String?);
        final realUrl = rawUrl != null ? fixStorageUrl(rawUrl) : filePath;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id != tempId) return m;
            return m.copyWith(mediaUrl: realUrl);
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('[Audio] Upload failed: $e');
      // Mark the bubble as failed so the user knows
      if (!_disposed) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id != tempId) return m;
            return m.copyWith(metadata: {...?m.metadata, 'upload_failed': true});
          }).toList(),
        );
      }
    }
  }

  // ── Called by ChatScreen after a file/image is picked ────────────────────

  Future<void> sendFileMessage(String filePath, String fileName, String mimeType) async {
    if (_disposed) return;

    final tempId = 'local_file_${DateTime.now().microsecondsSinceEpoch}';
    final isImage = mimeType.startsWith('image/');

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          id: tempId,
          text: fileName,
          type: MessageType.user,
          contentType: MessageContentType.file,
          mediaUrl: isImage ? filePath : null,
          createdAt: DateTime.now(),
          metadata: {'file_name': fileName, 'is_image': isImage},
        ),
      ],
    );

    if (_conversationId == null) return; // demo mode — nothing to upload

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await dio.post(
        '/conversations/$_conversationId/messages/file',
        data: formData,
      );
      final real = response.data?['data'] as Map<String, dynamic>?;
      if (real != null && !_disposed) {
        final rawUrl = (real['media_url'] as String?);
        final realUrl = rawUrl != null ? fixStorageUrl(rawUrl) : filePath;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id != tempId) return m;
            return m.copyWith(mediaUrl: realUrl);
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('[File] Upload failed: $e');
      if (!_disposed) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id != tempId) return m;
            return m.copyWith(metadata: {...?m.metadata, 'upload_failed': true});
          }).toList(),
        );
      }
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

  // ── Rate conversation ────────────────────────────────────────────────────

  Future<void> rateConversation(int conversationId, int rating, {String? comment}) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/conversations/$conversationId/rate', data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    } catch (e) {
      debugPrint('[Chat] rateConversation failed: $e');
      rethrow;
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

  // ── Escalate to human doctor ─────────────────────────────────────────────

  /// Calls POST /conversations/{id}/escalate.
  /// On 402 → sets escalate402Reason so the UI can redirect to /upgrade.
  Future<void> escalateToDoctor({int? expertId}) async {
    if (_conversationId == null) return;
    if (state.isEscalating) return;

    state = state.copyWith(isEscalating: true, clearEscalate402: true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/conversations/$_conversationId/escalate',
        data: expertId != null ? {'expert_id': expertId} : {},
      );
      // Conversation status updated — reload messages to pick up system message
      await _loadMessagesFromBackend(_conversationId!);
      if (!_disposed) state = state.copyWith(isEscalating: false);
    } on DioException catch (e) {
      if (!_disposed) {
        if (e.response?.statusCode == 402) {
          final msg = e.response?.data?['message'] as String? ?? '';
          final reason = msg.contains('crédits') ? 'no_credits' : 'no_plan';
          state = state.copyWith(isEscalating: false, escalate402Reason: reason);
        } else {
          final msg = e.response?.data?['message'] as String?
              ?? 'Impossible de transférer au médecin.';
          state = state.copyWith(isEscalating: false, error: msg);
        }
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          isEscalating: false,
          error: 'Erreur inattendue lors de l\'escalade.',
        );
      }
    }
  }

  void clearEscalate402() {
    if (!_disposed) state = state.copyWith(clearEscalate402: true);
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
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Per-conversation chat (doctor or escalated): auto-disposes when you leave.
final chatProvider =
    AutoDisposeNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

/// AI conversation: NOT auto-disposed — messages survive navigation.
final aiChatProvider =
    NotifierProvider<AiChatNotifier, ChatState>(AiChatNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Persistent AI-only notifier (same logic, extends Notifier not AutoDispose)
// ─────────────────────────────────────────────────────────────────────────────

class AiChatNotifier extends Notifier<ChatState> {
  bool _initialized = false;
  int? _conversationId;
  int? _viewerUserId;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  final _receivedMsgIds = <String>{}; // dedup guard
  final _optimisticUserMessages = <String>{}; // temp IDs of messages sent from THIS device
  int? _cachedCategoryId; // preloaded on initialize — eliminates GET /categories delay

  @override
  ChatState build() {
    ref.onDispose(() {
      _wsSub?.cancel();
      if (_conversationId != null) {
        ref.read(reverbServiceProvider).unsubscribe(_conversationId!);
      }
    });

    return const ChatState(messages: []);
  }

  /// Only initialises once; subsequent calls are no-ops.
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _viewerUserId = ref.read(currentUserProvider).valueOrNull?.id;
    // No welcome message — the empty state shows suggestion chips instead.
    // Preload category in background so first message has no extra delay.
    _preloadCategoryId();
  }

  /// Resets the notifier to a blank slate so the next open starts a fresh conversation.
  /// Call this before navigating to the AI chat from the FAB or home button.
  void reset() {
    _wsSub?.cancel();
    _wsSub = null;
    if (_conversationId != null) {
      try { ref.read(reverbServiceProvider).unsubscribe(_conversationId!); } catch (_) {}
    }
    _initialized = false;
    _conversationId = null;
    _cachedCategoryId = null;
    _receivedMsgIds.clear();
    _optimisticUserMessages.clear();
    state = const ChatState(messages: []);
    // Preload category in background so the next first message has no delay.
    _preloadCategoryId();
  }

  Future<void> _preloadCategoryId() async {
    try {
      final dio = ref.read(dioProvider);
      _cachedCategoryId = await _defaultCategoryId(dio);
    } catch (_) {
      // Non-critical — will retry inline when user sends first message
    }
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msg = _build(trimmed, MessageType.user);
    _optimisticUserMessages.add(msg.id); // track so WS echo from this device is identified

    state = state.copyWith(
      messages: [...state.messages, msg],
      isTyping: true,
      error: null,
    );

    if (_conversationId == null) {
      _createAiConversation(trimmed);
    } else {
      _postMessage(trimmed);
    }
  }

  Future<void> _createAiConversation(String firstMessage) async {
    try {
      final dio = ref.read(dioProvider);
      // Use preloaded category (no extra network call) — fallback to fetch if not ready
      final categoryId = _cachedCategoryId ?? await _defaultCategoryId(dio);
      final title = firstMessage.length > 60
          ? '${firstMessage.substring(0, 60)}...'
          : firstMessage;

      final response = await dio.post(
        '/conversations',
        data: {
          'category_id': categoryId,
          'title': title,
          'message': firstMessage,
        },
      );

      final payload = response.data?['data'] as Map<String, dynamic>? ?? {};
      final conversation = payload['conversation'] as Map<String, dynamic>? ?? payload;
      final conversationId = conversation['id'] as int?;

      if (conversationId == null) {
        throw StateError('Missing conversation id');
      }

      _conversationId = conversationId;
      ref.invalidate(conversationsProvider);
      await _startWebSocket(conversationId);

      // The AI pipeline (n8n → Groq → callback) can respond faster than our WS
      // subscription was established, causing the response to be missed.
      // Poll the backend at 1s and 4s to catch any AI message that slipped through.
      Future.delayed(const Duration(seconds: 1), () {
        if (_conversationId != null) _pollMissedMessages(conversationId);
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (_conversationId != null) _pollMissedMessages(conversationId);
      });
    } catch (e) {
      debugPrint('[AI Chat] Failed to create backend conversation: $e');
      receiveMessage(
        'Je n arrive pas a demarrer la consultation IA pour le moment. Reessayez dans un instant.',
        MessageType.ai,
      );
    }
  }

  /// Fetches messages from the backend and appends any AI/expert messages
  /// not yet present in local state. Used to recover responses that arrived
  /// before the WebSocket subscription was established.
  Future<void> _pollMissedMessages(int conversationId) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/conversations/$conversationId/messages');
      final data = response.data as Map<String, dynamic>;
      final messagesData = data['data'] as List<dynamic>? ?? [];

      final existingIds = state.messages.map((m) => m.id).toSet();

      final missed = <ChatMessage>[];
      for (final raw in messagesData) {
        final msgMap = raw as Map<String, dynamic>;
        final senderType = msgMap['sender_type'] as String? ?? 'ai';
        if (senderType == 'user') continue; // already optimistic in state

        final msgId = msgMap['id']?.toString() ?? '';
        if (msgId.isEmpty || existingIds.contains(msgId) || _receivedMsgIds.contains(msgId)) {
          continue;
        }

        final content = msgMap['content'] as String? ?? '';
        if (content.isEmpty) continue;

        _receivedMsgIds.add(msgId);
        final metadataRaw = msgMap['metadata'];
        final metadata = metadataRaw is Map
            ? Map<String, dynamic>.from(metadataRaw)
            : null;

        missed.add(ChatMessage(
          id: msgId,
          text: content,
          type: senderType == 'expert' ? MessageType.expert : MessageType.ai,
          createdAt: DateTime.tryParse(msgMap['created_at'] as String? ?? '') ?? DateTime.now(),
          metadata: metadata,
        ));
      }

      if (missed.isNotEmpty) {
        state = state.copyWith(
          messages: [...state.messages, ...missed],
          isTyping: false,
        );
      }
    } catch (_) {
      // Non-critical — silent failure
    }
  }

  Future<int> _defaultCategoryId(Dio dio) async {
    final response = await dio.get<Map<String, dynamic>>('/categories');
    final rawCategories = response.data?['data'] as List<dynamic>? ?? [];
    final categories = rawCategories
        .whereType<Map<String, dynamic>>()
        .toList();

    if (categories.isEmpty) {
      throw StateError('No active categories available');
    }

    final general = categories.firstWhere(
      (category) => category['slug'] == 'medecine-generale',
      orElse: () => categories.first,
    );

    return general['id'] as int;
  }

  Future<void> _postMessage(String text) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/conversations/$_conversationId/messages',
        data: {'content': text},
      );
    } catch (e) {
      debugPrint('[AI Chat] Failed to post message: $e');
      receiveMessage(
        'Je n arrive pas a envoyer votre message pour le moment. Reessayez dans un instant.',
        MessageType.ai,
      );
    }
  }

  Future<void> _startWebSocket(int conversationId) async {
    await _wsSub?.cancel();
    final stream = await ref
        .read(reverbServiceProvider)
        .subscribePrivate(conversationId);

    _wsSub = stream.listen((event) {
      final eventType = event['event'] as String?;
      final payload = event['payload'] as Map<String, dynamic>? ?? {};

      if (eventType == 'message.deleted') {
        final deletedId = payload['message_id']?.toString() ?? '';
        if (deletedId.isNotEmpty) deleteForMe(deletedId);
        return;
      }

      final msgData = payload['message'] as Map<String, dynamic>? ?? payload;
      final senderType = msgData['sender_type'] as String? ?? 'ai';
      final senderId = msgData['sender_id'] as int?;

      // User-type messages: update optimistic bubble's temp ID to server ID, then skip.
      // AI chat is always opened from history via chatProvider on other devices,
      // so we don't need to show cross-device user messages here.
      if (senderType == 'user') {
        final content2 = msgData['content'] as String? ?? '';
        final msgId2   = msgData['id']?.toString() ?? '';
        if (senderId == _viewerUserId && msgId2.isNotEmpty) {
          final matchIndex = state.messages.lastIndexWhere((m) =>
            m.type == MessageType.user &&
            m.text == content2 &&
            _optimisticUserMessages.contains(m.id),
          );
          if (matchIndex >= 0) {
            final tempId = state.messages[matchIndex].id;
            _optimisticUserMessages.remove(tempId);
            _receivedMsgIds.add(msgId2);
            final updated = List<ChatMessage>.from(state.messages);
            updated[matchIndex] = updated[matchIndex].copyWith(id: msgId2);
            state = state.copyWith(messages: updated);
          }
        }
        return; // always skip user messages in this notifier
      }
      if (senderId == _viewerUserId) return;

      final msgId = msgData['id']?.toString() ?? '';
      if (msgId.isNotEmpty && _receivedMsgIds.contains(msgId)) return;
      if (msgId.isNotEmpty) _receivedMsgIds.add(msgId);

      final content = msgData['content'] as String? ?? '';
      final wsType = (msgData['type'] as String?) ?? 'text';
      final isAudio = wsType == 'audio';
      final isFile = wsType == 'file';
      if (!isAudio && content.isEmpty) return;

      final rawUrl = (msgData['audio_url'] as String?) ?? (msgData['media_url'] as String?);
      final metadataRaw = msgData['metadata'];
      final metadata = metadataRaw is Map
          ? Map<String, dynamic>.from(metadataRaw)
          : null;
      final type = senderType == 'expert'
          ? MessageType.expert
          : MessageType.ai;

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: msgId,
            text: content,
            type: type,
            contentType: isAudio
                ? MessageContentType.audio
                : isFile
                    ? MessageContentType.file
                    : MessageContentType.text,
            mediaUrl: rawUrl != null ? fixStorageUrl(rawUrl) : null,
            createdAt: DateTime.now(),
            metadata: metadata,
          ),
        ],
        isTyping: false,
      );

      _markAllRead(conversationId);
    });
  }

  Future<void> sendAudioMessage(String filePath, {int durationSeconds = 0}) async {
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
          metadata: durationSeconds > 0 ? {'duration_seconds': durationSeconds} : null,
        ),
      ],
    );
    if (_conversationId == null) {
      receiveMessage(
        'Commencez par un court message ecrit, puis envoyez le vocal dans la consultation.',
        MessageType.ai,
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          filename: 'audio.m4a',
          contentType: DioMediaType('audio', 'mp4'),
        ),
      });
      final response = await dio.post(
        '/conversations/$_conversationId/messages/audio',
        data: formData,
      );
      final real = response.data?['data'] as Map<String, dynamic>?;
      if (real != null) {
        final rawUrl = (real['audio_url'] as String?) ?? (real['media_url'] as String?);
        final realUrl = rawUrl != null ? fixStorageUrl(rawUrl) : filePath;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id != tempId) return m;
            return m.copyWith(mediaUrl: realUrl);
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('[AI Chat] Audio upload failed: $e');
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id != tempId) return m;
          return m.copyWith(metadata: {...?m.metadata, 'upload_failed': true});
        }).toList(),
      );
    }
  }

  Future<void> sendFileMessage(String filePath, String fileName, String mimeType) async {
    final tempId = 'local_file_${DateTime.now().microsecondsSinceEpoch}';
    final isImage = mimeType.startsWith('image/');

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          id: tempId,
          text: fileName,
          type: MessageType.user,
          contentType: MessageContentType.file,
          mediaUrl: isImage ? filePath : null,
          createdAt: DateTime.now(),
          metadata: {'file_name': fileName, 'is_image': isImage},
        ),
      ],
    );

    if (_conversationId == null) {
      receiveMessage(
        'Commencez par un court message écrit, puis envoyez le fichier dans la consultation.',
        MessageType.ai,
      );
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await dio.post(
        '/conversations/$_conversationId/messages/file',
        data: formData,
      );
      final real = response.data?['data'] as Map<String, dynamic>?;
      if (real != null) {
        final rawUrl = real['media_url'] as String?;
        final realUrl = rawUrl != null ? fixStorageUrl(rawUrl) : filePath;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id != tempId) return m;
            return m.copyWith(mediaUrl: realUrl);
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('[AI Chat] File upload failed: $e');
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id != tempId) return m;
          return m.copyWith(metadata: {...?m.metadata, 'upload_failed': true});
        }).toList(),
      );
    }
  }

  Future<void> _markAllRead(int conversationId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/conversations/$conversationId/messages/read-all');
    } catch (_) {}
  }

  void receiveMessage(String text, MessageType type, {Map<String, dynamic>? metadata}) {
    state = state.copyWith(
      messages: [...state.messages, _build(text, type, metadata: metadata)],
      isTyping: false,
    );
  }

  void setTyping(bool value) {
    state = state.copyWith(isTyping: value);
  }

  void deleteForMe(String messageId) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) return m.copyWith(isDeleted: true);
        return m;
      }).toList(),
    );
  }

  void clearEscalate402() {
    state = state.copyWith(clearEscalate402: true);
  }

  /// Escalate the current AI conversation to a human doctor.
  /// Same logic as ChatNotifier.escalateToDoctor but uses AiChatNotifier's conversationId.
  Future<void> escalateToDoctor({int? expertId}) async {
    if (_conversationId == null) return;
    if (state.isEscalating) return;

    state = state.copyWith(isEscalating: true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/conversations/$_conversationId/escalate',
        data: expertId != null ? {'expert_id': expertId} : {},
      );
      state = state.copyWith(isEscalating: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        final msg = e.response?.data?['message'] as String? ?? '';
        final reason = msg.contains('crédits') ? 'no_credits' : 'no_plan';
        state = state.copyWith(isEscalating: false, escalate402Reason: reason);
      } else {
        state = state.copyWith(
          isEscalating: false,
          error: 'Impossible de transférer au médecin.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isEscalating: false,
        error: 'Erreur inattendue lors de l\'escalade.',
      );
    }
  }

  ChatMessage _build(String text, MessageType type, {Map<String, dynamic>? metadata}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        type: type,
        createdAt: DateTime.now(),
        metadata: metadata,
      );
}
