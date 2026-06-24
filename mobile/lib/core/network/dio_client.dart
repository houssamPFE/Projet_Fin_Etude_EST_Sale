import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../services/token_storage.dart';

// Retrieve custom BASE_URL if passed via --dart-define=BASE_URL, default to emulator IP
const kBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

final String _apiHost = Uri.parse(kBaseUrl).host;

/// Rewrites Docker-internal storage hostnames to the base URL host so the
/// device (emulator or real phone) can reach MinIO running on the host machine.
String fixStorageUrl(String url) {
  return url
      .replaceFirst(RegExp(r'http://minio:'), 'http://$_apiHost:')
      .replaceFirst(RegExp(r'http://localhost:'), 'http://$_apiHost:')
      .replaceFirst(RegExp(r'http://127\.0\.0\.1:'), 'http://$_apiHost:');
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
      // Notify the router so it re-evaluates auth state and redirects to
      // the welcome screen instead of leaving the user on a broken home screen.
      notifyAuthChanged();
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
// Maintenance interceptor — on 503 + maintenance flag, redirect to /maintenance
// Login calls are exempt: the login screen handles maintenance inline.
// ─────────────────────────────────────────────────────────────────────────────

class _MaintenanceInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isLoginCall = err.requestOptions.path.contains('/auth/login');
    if (!isLoginCall &&
        err.response?.statusCode == 503 &&
        err.response?.data is Map &&
        (err.response?.data as Map)['maintenance'] == true) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        GoRouter.of(ctx).go(AppRoutes.maintenance);
      }
    }
    handler.next(err);
  }
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
  dio.interceptors.add(_MaintenanceInterceptor());
  dio.interceptors.add(_AuthInterceptor(storage));
  dio.interceptors.add(_RefreshInterceptor(storage));
  return dio;
});
