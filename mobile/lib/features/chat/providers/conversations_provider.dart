import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/offline_cache_service.dart';
import '../services/conversation_service.dart';

final conversationServiceProvider = Provider((ref) {
  return ConversationService(ref.read(dioProvider));
});

// Live connectivity stream — drives the offline banner in the UI
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Convenience bool: true when device has no network
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
    data: (results) => results.every((r) => r == ConnectivityResult.none),
    orElse: () => false,
  );
});

// Conversations with offline cache fallback
final conversationsProvider = FutureProvider((ref) async {
  final service = ref.watch(conversationServiceProvider);
  final cache   = ref.read(offlineCacheProvider);

  final connectivity = await Connectivity().checkConnectivity();
  final isOffline    = connectivity.every((r) => r == ConnectivityResult.none);

  if (isOffline) {
    final cached = await cache.loadConversations();
    return _filter(cached ?? []);
  }

  try {
    final conversations = await service.getConversations();
    await cache.saveConversations(conversations); // keep cache fresh
    return _filter(conversations);
  } catch (_) {
    // Network error — fall back to cache silently
    final cached = await cache.loadConversations();
    if (cached != null) return _filter(cached);
    rethrow;
  }
});

List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list) => list;

/// When set to true, ConversationsScreen auto-switches to the IA filter tab.
final aiFilterRequestedProvider = StateProvider<bool>((ref) => false);
