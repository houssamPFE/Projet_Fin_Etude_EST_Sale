import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_storage.dart';

// Android emulator → 10.0.2.2 maps to host machine's localhost
// iOS simulator   → localhost
// Physical device → LAN IP of the dev machine (same WiFi network)
const kBaseUrl = 'http://10.0.2.2:8000/api/v1';

// ─────────────────────────────────────────────────────────────────────────────
// Auth interceptor — injects Bearer token on every outgoing request
// ─────────────────────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final TokenStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dio singleton provider
// ─────────────────────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(_AuthInterceptor(ref.read(tokenStorageProvider)));
  return dio;
});
