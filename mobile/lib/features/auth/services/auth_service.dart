import 'package:dio/dio.dart';
import '../models/auth_response.dart';

class AuthService {
  const AuthService(this._dio);

  final Dio _dio;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data!;
    if (data['requires_2fa'] == true) {
      return LoginNeeds2FA(
        twoFactorToken: data['two_factor_token'] as String,
      );
    }
    return LoginSuccess.fromJson(data);
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
    return RegisterResponse.fromJson(res.data!);
  }

  // ── Email OTP verification (auto-logs in on success) ─────────────────────

  Future<LoginSuccess> verifyEmail({
    required String email,
    required String code,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-email',
      data: {'email': email, 'code': code},
    );
    return LoginSuccess.fromJson(res.data!);
  }

  Future<void> resendOtp({required String email}) async {
    await _dio.post('/auth/resend-otp', data: {'email': email});
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<void> forgotPassword({required String email}) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _dio.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': password,
    });
  }

  // ── 2FA ───────────────────────────────────────────────────────────────────

  Future<LoginSuccess> verify2fa({
    required String twoFactorToken,
    required String code,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/2fa/verify',
      data: {'two_factor_token': twoFactorToken, 'code': code},
    );
    return LoginSuccess.fromJson(res.data!);
  }

  // ── Social OAuth (native token exchange) ─────────────────────────────────

  Future<LoginResult> socialLogin({
    required String provider,
    required String token,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/social/token',
      data: {'provider': provider, 'token': token},
    );
    final data = res.data!;
    if (data['requires_2fa'] == true) {
      return LoginNeeds2FA(twoFactorToken: data['two_factor_token'] as String);
    }
    return LoginSuccess.fromJson(data);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}
