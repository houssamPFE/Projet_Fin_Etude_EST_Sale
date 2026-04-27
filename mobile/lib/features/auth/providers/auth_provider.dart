import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/token_storage.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final String? error;
  final String? infoMessage;

  const AuthState({this.isLoading = false, this.error, this.infoMessage});

  AuthState copyWith({bool? isLoading, String? error, String? infoMessage}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        infoMessage: infoMessage,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AutoDisposeNotifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _service => AuthService(ref.read(dioProvider));
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  // Returns true on success — screen navigates on true
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final res = await _service.login(email: email, password: password);
      await _storage.save(res.accessToken);
      state = const AuthState();
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (e) {
      state = AuthState(error: 'Réponse inattendue du serveur. ($e)');
      return false;
    }
  }

  // Returns true on success. Backend requires email verification before login,
  // so register does NOT produce a token — caller should redirect to login.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final res = await _service.register(
        name: name,
        email: email,
        password: password,
      );
      state = AuthState(infoMessage: res.message);
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (e) {
      state = AuthState(error: 'Réponse inattendue du serveur. ($e)');
      return false;
    }
  }

  Future<void> logout() => _storage.delete();

  // ── Error parsing ─────────────────────────────────────────────────────────

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Laravel returns { message: "...", errors: {...} }
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connexion trop lente. Vérifiez votre réseau.',
      DioExceptionType.connectionError =>
        'Impossible de joindre le serveur.',
      _ => 'Une erreur est survenue. Réessayez.',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final authProvider =
    AutoDisposeNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
