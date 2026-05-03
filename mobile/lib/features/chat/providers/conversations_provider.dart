import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/conversation_service.dart';

final conversationServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return ConversationService(dio);
});

// Load all conversations (exclude closed ones)
final conversationsProvider = FutureProvider((ref) async {
  final service = ref.watch(conversationServiceProvider);
  final conversations = await service.getConversations();

  return conversations.where((c) {
    final status = c['status'] as String?;
    return status != 'closed';
  }).toList();
});

