import 'package:dio/dio.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' hide LoginResult;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/token_storage.dart';
import '../models/auth_response.dart';
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

  AuthService   get _service => AuthService(ref.read(dioProvider));
  TokenStorage  get _storage => ref.read(tokenStorageProvider);

  // ── Login ─────────────────────────────────────────────────────────────────
  // Returns LoginResult on success, null on error.
  // Caller is responsible for navigation.

  Future<LoginResult?> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final result = await _service.login(email: email, password: password);
      if (result is LoginSuccess) {
        await _storage.saveTokens(result.accessToken, result.refreshToken);
        notifyAuthChanged();
      }
      state = const AuthState();
      return result;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['requires_verification'] == true) {
        state = const AuthState();
        return LoginNeedsVerification();
      }
      state = AuthState(error: _dioMessage(e));
      return null;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  // Returns email on success (to pass to OTP screen), null on error.

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await _service.register(name: name, email: email, password: password);
      state = const AuthState();
      return email;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return null;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return null;
    }
  }

  // ── Email OTP ─────────────────────────────────────────────────────────────

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final result = await _service.verifyEmail(email: email, code: code);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      notifyAuthChanged();
      state = const AuthState();
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return false;
    }
  }

  Future<bool> resendOtp({required String email}) async {
    state = const AuthState(isLoading: true);
    try {
      await _service.resendOtp(email: email);
      state = const AuthState(infoMessage: 'Code renvoyé avec succès.');
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return false;
    }
  }

  // ── Forgot / Reset password ───────────────────────────────────────────────

  Future<bool> forgotPassword({required String email}) async {
    state = const AuthState(isLoading: true);
    try {
      await _service.forgotPassword(email: email);
      state = const AuthState();
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await _service.resetPassword(email: email, code: code, password: password);
      state = const AuthState();
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return false;
    }
  }

  // ── 2FA ───────────────────────────────────────────────────────────────────

  Future<bool> verify2fa({
    required String twoFactorToken,
    required String code,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final result = await _service.verify2fa(
        twoFactorToken: twoFactorToken,
        code: code,
      );
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      notifyAuthChanged();
      state = const AuthState();
      return true;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return false;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return false;
    }
  }

  // ── Social OAuth — native sign-in ─────────────────────────────────────────

  Future<LoginResult?> loginWithGoogle() async {
    state = const AuthState(isLoading: true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '838155054639-cn48046dqe7hq02svq3etae8eeqdh26f.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
        );
      await googleSignIn.signOut(); // force account picker every time
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = const AuthState();
        return null;
      }
      final auth = await googleUser.authentication;
      final token = auth.accessToken;
      if (token == null) throw Exception('No access token from Google');
      return await _socialLogin('google', token);
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return null;
    } catch (_) {
      state = const AuthState(error: 'Connexion Google échouée. Réessayez.');
      return null;
    }
  }

  Future<LoginResult?> loginWithFacebook() async {
    state = const AuthState(isLoading: true);
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) {
        state = const AuthState();
        return null;
      }
      final token = result.accessToken!.token;
      return await _socialLogin('facebook', token);
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return null;
    } catch (_) {
      state = const AuthState(error: 'Connexion Facebook échouée. Réessayez.');
      return null;
    }
  }

  Future<LoginResult?> _socialLogin(String provider, String token) async {
    try {
      final result = await _service.socialLogin(provider: provider, token: token);
      if (result is LoginSuccess) {
        await _storage.saveTokens(result.accessToken, result.refreshToken);
        notifyAuthChanged();
      }
      state = const AuthState();
      return result;
    } on DioException catch (e) {
      state = AuthState(error: _dioMessage(e));
      return null;
    } catch (_) {
      state = const AuthState(error: 'Réponse inattendue du serveur.');
      return null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.deleteAll();
    notifyAuthChanged();
  }

  // ── Error parsing ─────────────────────────────────────────────────────────

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
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
