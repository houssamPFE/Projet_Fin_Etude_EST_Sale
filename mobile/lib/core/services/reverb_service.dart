import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../network/dio_client.dart';
import '../services/token_storage.dart';

final _kReverbHost   = Uri.parse(kBaseUrl).host;
const _kReverbWsPort = 8080;
const _kReverbAppKey = 'nexora-key';

class ReverbService {
  final Dio          _dio;
  final TokenStorage _storage;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _socketId;
  bool _disposed = false;

  final Map<String, StreamController<Map<String, dynamic>>> _channels = {};

  ReverbService(this._dio, this._storage);

  void dispose() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    for (final c in _channels.values) {
      c.close();
    }
    _channels.clear();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<Stream<Map<String, dynamic>>> subscribePrivate(int conversationId) async {
    final name = 'private-conversation.$conversationId';
    return _ensureSubscribed(name);
  }

  Future<Stream<Map<String, dynamic>>> subscribeUser(int userId) async {
    final name = 'private-user.$userId';
    return _ensureSubscribed(name);
  }

  Future<Stream<Map<String, dynamic>>> _ensureSubscribed(String name) async {
    if (!_channels.containsKey(name)) {
      _channels[name] = StreamController<Map<String, dynamic>>.broadcast();
    }
    if (_socketId == null) {
      await _connect();
    } else {
      await _subscribeChannel(name);
    }
    return _channels[name]!.stream;
  }

  void unsubscribe(int conversationId) {
    final name = 'private-conversation.$conversationId';
    _unsubscribeChannel(name);
  }

  void unsubscribeUser(int userId) {
    final name = 'private-user.$userId';
    _unsubscribeChannel(name);
  }

  void _unsubscribeChannel(String name) {
    _channels[name]?.close();
    _channels.remove(name);
    if (_channel != null && _socketId != null) {
      _channel!.sink.add(jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {'channel': name},
      }));
    }
  }

  // ── Connection ─────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    final uri = Uri(
      scheme: 'ws',
      host: _kReverbHost,
      port: _kReverbWsPort,
      path: '/app/$_kReverbAppKey',
      queryParameters: {
        'protocol': '7',
        'client':   'flutter',
        'version':  '8.0.0',
      },
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone:  ()  { if (!_disposed) _scheduleReconnect(); },
      );
    } catch (e) {
      debugPrint('[Reverb] connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketId = null;
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) _connect();
    });
  }

  // ── Message handling ───────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final frame  = jsonDecode(raw as String) as Map<String, dynamic>;
      final event  = frame['event']   as String?;
      final data   = frame['data'];
      final ch     = frame['channel'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          final conn = jsonDecode(data as String) as Map<String, dynamic>;
          _socketId = conn['socket_id'] as String?;
          debugPrint('[Reverb] connected, socket_id=$_socketId');
          _startPing();
          for (final name in _channels.keys) {
            _subscribeChannel(name);
          }

        case 'pusher:pong':
          break;

        case 'pusher_internal:subscription_succeeded':
          debugPrint('[Reverb] subscribed: $ch');

        // broadcastAs('message.sent') — MessageSent event
        // broadcastAs('ai.response') — AIResponseReady event
        case 'message.sent':
        case 'ai.response':
          if (ch != null && _channels.containsKey(ch)) {
            final payload = data is String
                ? jsonDecode(data) as Map<String, dynamic>
                : data as Map<String, dynamic>;
            _channels[ch]!.add({'event': event, 'payload': payload});
          }

        // broadcastAs('user.typing') — UserTyping event
        case 'user.typing':
          if (ch != null && _channels.containsKey(ch)) {
            final payload = data is String
                ? jsonDecode(data) as Map<String, dynamic>
                : data as Map<String, dynamic>;
            _channels[ch]!.add({'event': 'typing', 'payload': payload});
          }

        case 'App\\Events\\NotificationReceived':
        case 'App\\Events\\ConversationAssigned':
          if (ch != null && _channels.containsKey(ch)) {
            final payload = data is String
                ? jsonDecode(data) as Map<String, dynamic>
                : data as Map<String, dynamic>;
            _channels[ch]!.add({'event': event, 'payload': payload});
          }

        case 'message.deleted':
          if (ch != null && _channels.containsKey(ch)) {
            final payload = data is String
                ? jsonDecode(data) as Map<String, dynamic>
                : data as Map<String, dynamic>;
            _channels[ch]!.add({'event': 'message.deleted', 'payload': payload});
          }

        // broadcastAs('user.presence') — UserPresenceChanged event
        case 'user.presence':
          if (ch != null && _channels.containsKey(ch)) {
            final payload = data is String
                ? jsonDecode(data) as Map<String, dynamic>
                : data as Map<String, dynamic>;
            _channels[ch]!.add({'event': 'user.presence', 'payload': payload});
          }
      }
    } catch (e) {
      debugPrint('[Reverb] parse error: $e');
    }
  }

  // ── Channel auth + subscribe ───────────────────────────────────────────────

  Future<void> _subscribeChannel(String name) async {
    if (_socketId == null) return;

    String auth = '';
    try {
      final token = await _storage.read();
      final baseUri = Uri.parse(kBaseUrl);
      final authUrl = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}/broadcasting/auth';
      final res = await _dio.post(
        authUrl,
        data: {'socket_id': _socketId, 'channel_name': name},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      auth = (res.data as Map<String, dynamic>)['auth'] as String? ?? '';
    } catch (e) {
      debugPrint('[Reverb] auth failed for $name: $e');
      return;
    }

    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': name, 'auth': auth},
    }));
  }

  // ── Keepalive ──────────────────────────────────────────────────────────────

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
    });
  }
}

final reverbServiceProvider = Provider<ReverbService>((ref) {
  final service = ReverbService(
    ref.read(dioProvider),
    ref.read(tokenStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
