import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/auth_response.dart';

// Fetches the currently authenticated user from GET /auth/me.
// Backend response: { data: { id, name, email, avatar_url, ... } }
final currentUserProvider = FutureProvider<AuthUser>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/auth/me');
  final data = res.data!['data'] as Map<String, dynamic>;
  return AuthUser.fromJson(data);
});
