import 'package:dio/dio.dart';

class ConversationService {
  final Dio _dio;

  ConversationService(this._dio);

  Future<Map<String, dynamic>> createConversation({
    required int categoryId,
    required String message,
    String? title,
  }) async {
    final response = await _dio.post(
      '/conversations',
      data: {
        'category_id': categoryId,
        'message': message,
        if (title != null) 'title': title,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>;
    return payload['conversation'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _dio.get('/conversations');
    final data = response.data as Map<String, dynamic>;
    final conversations = data['data'] as List<dynamic>? ?? [];
    return conversations.map((c) => c as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    final data = response.data as Map<String, dynamic>;
    final messages = data['data'] as List<dynamic>? ?? [];
    return messages.map((m) => m as Map<String, dynamic>).toList();
  }

  Future<void> sendMessage(int conversationId, String content) async {
    await _dio.post(
      '/conversations/$conversationId/messages',
      data: {'content': content},
    );
  }
}
