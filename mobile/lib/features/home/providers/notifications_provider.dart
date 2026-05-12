import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/reverb_service.dart';
import '../../auth/providers/current_user_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = true,
    this.error,
  });

  int get unreadCount => notifications.where((n) => n['read_at'] == null).length;

  NotificationsState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? isLoading,
    String? error,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  int? _userId;
  StreamSubscription? _wsSub;

  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    _init();
  }

  Future<void> _init() async {
    await _fetchInitial();
    await _subscribeRealtime();
  }

  // ── Fetch from API ──────────────────────────────────────────────────────────

  Future<void> _fetchInitial() async {
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/notifications');
      final data = res.data!['data'] as List;
      final list = data.map((n) => n as Map<String, dynamic>).toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetchInitial();

  // ── WebSocket real-time ─────────────────────────────────────────────────────

  Future<void> _subscribeRealtime() async {
    try {
      // Get current user ID
      final user = await _ref.read(currentUserProvider.future);
      _userId = user.id;

      final reverb = _ref.read(reverbServiceProvider);
      final stream = await reverb.subscribeUser(user.id);

      _wsSub = stream.listen((msg) {
        final event = msg['event'] as String?;
        if (event == 'App\\Events\\NotificationReceived' ||
            event == 'App\\Events\\ConversationAssigned') {
          _onNewNotification(msg['payload'] as Map<String, dynamic>);
        }
      });
    } catch (e) {
      // WebSocket failure is non-fatal — REST data still shows
    }
  }

  void _onNewNotification(Map<String, dynamic> payload) {
    // The payload mirrors the notifications table row
    final notif = payload['notification'] as Map<String, dynamic>? ?? payload;
    final current = List<Map<String, dynamic>>.from(state.notifications);
    // Prepend — newest first, avoid duplicates
    final exists = current.any((n) => n['id'] == notif['id']);
    if (!exists) {
      state = state.copyWith(notifications: [notif, ...current]);
    }
  }

  // ── Mark as read ────────────────────────────────────────────────────────────

  Future<void> markRead(dynamic id) async {
    // Optimistic update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n['id'] == id) return {...n, 'read_at': DateTime.now().toIso8601String()};
        return n;
      }).toList(),
    );
    try {
      final dio = _ref.read(dioProvider);
      await dio.put('/notifications/$id/read');
    } catch (_) {
      // Revert on failure
      await _fetchInitial();
    }
  }

  Future<void> markAllRead() async {
    // Optimistic update
    final now = DateTime.now().toIso8601String();
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n['read_at'] == null ? {...n, 'read_at': now} : n)
          .toList(),
    );
    try {
      final dio = _ref.read(dioProvider);
      await dio.put('/notifications/read-all');
    } catch (_) {
      await _fetchInitial();
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    if (_userId != null) {
      _ref.read(reverbServiceProvider).unsubscribeUser(_userId!);
    }
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});

/// Convenience: unread badge count for the bell icon
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsNotifierProvider).unreadCount;
});
