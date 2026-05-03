import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/auth_response.dart';

// Holds the local file path of a picked avatar so it survives navigation.
// Cleared when the user logs out or picks a new photo.
final localAvatarPathProvider = StateProvider<String?>((ref) => null);

// Fetches the currently authenticated user from GET /auth/me.
// Backend response: { data: { id, name, email, avatar_url, ... } }
final currentUserProvider = FutureProvider<AuthUser>((ref) async {
  final dio = ref.watch(dioProvider);
  Exception? lastError;
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      final res = await dio.get<Map<String, dynamic>>('/auth/me');
      final data = res.data!['data'] as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    } catch (e) {
      lastError = Exception(e.toString());
      if (attempt < 2) await Future.delayed(Duration(seconds: attempt + 1));
    }
  }
  throw lastError!;
});
