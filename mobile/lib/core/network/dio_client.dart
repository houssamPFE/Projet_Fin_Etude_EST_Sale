import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_storage.dart';

// Android emulator → 10.0.2.2 maps to host machine's localhost
const kBaseUrl = 'http://10.0.2.2:8000/api/v1';

/// Rewrites Docker-internal storage hostnames to 10.0.2.2 so the Android
/// emulator can reach MinIO running on the host machine.
String fixStorageUrl(String url) {
  return url
      .replaceFirst(RegExp(r'http://minio:'), 'http://10.0.2.2:')
      .replaceFirst(RegExp(r'http://localhost:'), 'http://10.0.2.2:')
      .replaceFirst(RegExp(r'http://127\.0\.0\.1:'), 'http://10.0.2.2:');
}

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
// Refresh interceptor — on 401, silently refreshes token and retries once
// ─────────────────────────────────────────────────────────────────────────────

class _RefreshInterceptor extends QueuedInterceptor {
  final TokenStorage _storage;
  _RefreshInterceptor(this._storage);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    try {
      final refreshDio = _makeBaseDio();
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final token = data['token'] as Map<String, dynamic>;
      final newAccess  = token['access_token']  as String;
      final newRefresh = token['refresh_token'] as String;

      await _storage.saveTokens(newAccess, newRefresh);

      // Retry original request with new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await refreshDio.fetch(err.requestOptions);
      return handler.resolve(retried);
    } catch (_) {
      await _storage.deleteAll();
      return handler.next(err);
    }
  }

  Dio _makeBaseDio() => Dio(
        BaseOptions(
          baseUrl: kBaseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dio singleton provider
// ─────────────────────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(_AuthInterceptor(storage));
  dio.interceptors.add(_RefreshInterceptor(storage));
  return dio;
});
