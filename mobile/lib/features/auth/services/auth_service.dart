import 'package:dio/dio.dart';
import '../models/auth_response.dart';

class AuthService {
  const AuthService(this._dio);

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(res.data!);
  }

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
}
