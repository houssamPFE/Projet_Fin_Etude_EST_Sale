// ignore_for_file: unused_field
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/chat_message.dart';
import '../services/conversation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI Mock Responses (for IA Nexora chat — no backend conversation needed)
// ─────────────────────────────────────────────────────────────────────────────

const _kAiResponses = [
  'Bonjour ! Je suis l\'IA Nexora. Comment puis-je vous aider aujourd\'hui ?',
  'Je comprends. Pouvez-vous me donner plus de détails ?',
  'Merci pour cette précision. D\'après mon analyse, je vous recommande de consulter un spécialiste.',
  'C\'est noté. Depuis combien de temps ressentez-vous cela ?',
  'Je vais analyser votre demande. Avez-vous déjà consulté un expert pour ce problème ?',
  'D\'accord. Je peux vous mettre en relation avec un expert si vous le souhaitez.',
];

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isLoading,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends AutoDisposeNotifier<ChatState> {
  Timer? _pollingTimer;
  bool _disposed = false;
  bool _isAi = true;
  int? _conversationId;
  DateTime _lastPolled = DateTime.now();

  @override
  ChatState build() {
    ref.onDispose(() {
      _disposed = true;
      _stopPolling();
    });
    return const ChatState(messages: []);
  }

  // ── Called by ChatScreen on open ─────────────────────────────────────────

  void initialize({required bool isAi, int? conversationId}) {
    _isAi = isAi;

    if (conversationId != null) {
      _conversationId = conversationId;
      _loadMessagesFromBackend(conversationId);
      _startPolling();
    } else if (isAi) {
      // IA Nexora chat — show welcome message, no backend
      state = state.copyWith(
        messages: [
          ChatMessage(
            id: 'ai_welcome',
            text: _kAiResponses[0],
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
        final type = msgMap['sender_type'] == 'user'
            ? MessageType.user
            : msgMap['sender_type'] == 'expert'
                ? MessageType.expert
                : MessageType.ai;

        return ChatMessage(
          id: msgMap['id']?.toString() ?? '',
          text: msgMap['content'] as String? ?? '',
          type: type,
          createdAt: msgMap['created_at'] is String
              ? DateTime.tryParse(msgMap['created_at'] as String) ??
                  DateTime.now()
              : DateTime.now(),
        );
      }).toList();

      if (!_disposed) {
        state = state.copyWith(messages: messages, isLoading: false);
      }
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

  // ── Message polling (real-time substitute) ──────────────────────────────────

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        if (_disposed || _conversationId == null) return;
        await _pollForNewMessages();
      },
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollForNewMessages() async {
    if (_conversationId == null) return;

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/conversations/$_conversationId/messages?since=${_lastPolled.toIso8601String()}',
      );
      final data = response.data as Map<String, dynamic>;
      final messagesData = data['data'] as List<dynamic>? ?? [];

      if (messagesData.isNotEmpty) {
        _lastPolled = DateTime.now();

        for (final msg in messagesData) {
          final msgMap = msg as Map<String, dynamic>;

          final type = msgMap['type'] == 'user'
              ? MessageType.user
              : msgMap['type'] == 'expert'
                  ? MessageType.expert
                  : MessageType.ai;

          final message = ChatMessage(
            id: msgMap['id']?.toString() ?? '',
            text: msgMap['content'] as String? ?? '',
            type: type,
            createdAt: msgMap['created_at'] is String
                ? DateTime.tryParse(msgMap['created_at'] as String) ??
                    DateTime.now()
                : DateTime.now(),
          );

          if (!_disposed && !state.messages.any((m) => m.id == message.id)) {
            state = state.copyWith(
              messages: [...state.messages, message],
              isTyping: false,
            );
          }
        }
      }
    } catch (e) {
      // Polling error — retry next cycle
    }
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

    final reply = _kAiResponses[
        (state.messages.length) % _kAiResponses.length];
    receiveMessage(reply, MessageType.ai);
  }

  // ── Called by WebSocket layer when a message arrives ─────────────────────

  void receiveMessage(String text, MessageType type) {
    if (_disposed) return;
    state = state.copyWith(
      messages: [...state.messages, _build(text, type)],
      isTyping: false,
    );
  }

  // ── Called by WebSocket layer on typing events ────────────────────────────

  void setTyping(bool value) {
    if (_disposed) return;
    state = state.copyWith(isTyping: value);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ChatMessage _build(String text, MessageType type) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        type: type,
        createdAt: DateTime.now(),
      );

}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final chatProvider =
    AutoDisposeNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
