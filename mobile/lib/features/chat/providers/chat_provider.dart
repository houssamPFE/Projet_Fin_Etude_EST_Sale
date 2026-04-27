// ignore_for_file: unused_field
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock responses — replace with WebSocket payloads when integrating
// ─────────────────────────────────────────────────────────────────────────────

const _kAiResponses = [
  'Je comprends. Pouvez-vous me donner plus de détails sur vos symptômes ?',
  'Merci pour cette précision. D\'après mon analyse, je vous recommande de consulter un spécialiste.',
  'C\'est noté. Depuis combien de temps ressentez-vous ces symptômes ?',
  'Je vais analyser votre demande. Avez-vous déjà consulté un médecin pour ce problème ?',
];

const _kExpertResponses = [
  'Merci pour cette précision. Je vais examiner cela attentivement.',
  'C\'est important à noter. Pouvez-vous me décrire la fréquence de ces épisodes ?',
  'D\'accord. Je vous recommande de faire un bilan complet pour confirmer le diagnostic.',
  'Bien reçu. Avez-vous pris des médicaments récemment pour soulager ces symptômes ?',
];

// ─────────────────────────────────────────────────────────────────────────────
// Initial seed messages — replace with GET /conversations/:id/messages
// ─────────────────────────────────────────────────────────────────────────────

List<ChatMessage> _buildSeedMessages() {
  final today = DateTime.now();

  DateTime t(int h, int m) =>
      DateTime(today.year, today.month, today.day, h, m);

  return [
    ChatMessage(
      id: 'seed_0',
      text:
          'Bonjour ! Je suis l\'IA Nexora. Décrivez votre problème et je vais analyser votre demande pour vous aider ou vous connecter à l\'expert idéal.',
      type: MessageType.ai,
      createdAt: t(14, 2),
    ),
    ChatMessage(
      id: 'seed_1',
      text: 'J\'ai des douleurs thoraciques depuis ce matin.',
      type: MessageType.user,
      createdAt: t(14, 3),
    ),
    ChatMessage(
      id: 'seed_2',
      text:
          'Les douleurs thoraciques peuvent avoir plusieurs origines. Sont-elles constantes ou intermittentes ? Irradient-elles vers le bras gauche ou la mâchoire ?',
      type: MessageType.ai,
      createdAt: t(14, 3),
    ),
    ChatMessage(
      id: 'seed_3',
      text: 'Intermittentes, et ça monte un peu vers l\'épaule gauche.',
      type: MessageType.user,
      createdAt: t(14, 5),
    ),
    ChatMessage(
      id: 'seed_4',
      text: 'IA Nexora vous a connecté à un expert médical',
      type: MessageType.system,
      createdAt: t(14, 5),
    ),
    ChatMessage(
      id: 'seed_5',
      text:
          'Bonjour ! J\'ai pris connaissance de vos symptômes. Une irradiation vers l\'épaule gauche mérite une attention particulière. Avez-vous des antécédents cardiaques ?',
      type: MessageType.expert,
      createdAt: t(14, 6),
    ),
    ChatMessage(
      id: 'seed_6',
      text: 'Non, aucun antécédent. Beaucoup de stress ces derniers temps.',
      type: MessageType.user,
      createdAt: t(14, 7),
    ),
    ChatMessage(
      id: 'seed_7',
      text:
          'Le stress peut effectivement provoquer des douleurs thoraciques. Je vous recommande tout de même un ECG aujourd\'hui pour écarter tout risque cardiaque. Avez-vous accès à une clinique proche ?',
      type: MessageType.expert,
      createdAt: t(14, 8),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends AutoDisposeNotifier<ChatState> {
  bool _disposed = false;
  bool _isAi = true;
  int? _conversationId; // set when WebSocket connects

  @override
  ChatState build() {
    ref.onDispose(() {
      _disposed = true;
      _disconnectWebSocket();
    });
    return const ChatState();
  }

  // ── Called by ChatScreen on open ─────────────────────────────────────────

  void initialize({required bool isAi, int? conversationId}) {
    _isAi = isAi;
    _conversationId = conversationId;
    state = state.copyWith(messages: _buildSeedMessages());

    // TODO(S17): call connectWebSocket() once conversationId is available
    // connectWebSocket(conversationId!);
  }

  // ── WebSocket lifecycle ───────────────────────────────────────────────────

  // TODO(S17): inject a WebSocket/Reverb client and subscribe to
  //   private-conversation.{_conversationId}
  //   Events to handle:
  //     MessageSent        → receiveMessage(text, type)
  //     UserTyping (whisper) → setTyping(true/false)
  //     AIResponseReady    → receiveMessage(text, MessageType.ai)
  void connectWebSocket(int conversationId) {
    // TODO(S17): Echo.private('conversation.$conversationId')
    //   .listen('MessageSent', (data) => receiveMessage(data['content'], ...))
    //   .listenForWhisper('typing', (data) => setTyping(data['typing']))
  }

  void _disconnectWebSocket() {
    // TODO(S17): Echo.leave('conversation.$_conversationId')
  }

  // ── Called by ChatScreen when user submits a message ─────────────────────

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(
      messages: [...state.messages, _build(trimmed, MessageType.user)],
    );

    // TODO(S17): POST /api/v1/conversations/{id}/messages via HTTP, then
    //   server broadcasts MessageSent → receiveMessage() is called by WebSocket
    _mockResponse(); // remove when WebSocket is connected
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

  // ── Mock response simulation — remove when WebSocket is connected ─────────

  Future<void> _mockResponse() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (_disposed) return;

    setTyping(true);

    await Future.delayed(const Duration(milliseconds: 2000));
    if (_disposed) return;

    final pool = _isAi ? _kAiResponses : _kExpertResponses;
    final text = pool[state.messages.length % pool.length];
    final type = _isAi ? MessageType.ai : MessageType.expert;

    receiveMessage(text, type);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final chatProvider =
    AutoDisposeNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
