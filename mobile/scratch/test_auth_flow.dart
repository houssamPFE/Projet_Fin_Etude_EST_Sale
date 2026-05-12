import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/api/v1',
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    validateStatus: (status) => true,
  ));

  print('=== FULL AUTH FLOW TEST ===\n');

  // ── Login with verified user ──────────────────────────────────────────────
  print('1. POST /auth/login (verified user)');
  final loginRes = await dio.post('/auth/login', data: {
    'email': 'mobiletest_1778080332734@nexora.test',
    'password': 'SecurePass123!',
  });
  print('   Status: ${loginRes.statusCode}');
  print('   Full response:');
  print(const JsonEncoder.withIndent('  ').convert(loginRes.data));

  if (loginRes.statusCode != 200) {
    print('\n   ✗ Login failed, cannot proceed.');
    return;
  }

  // Extract tokens
  final data = loginRes.data['data'] as Map<String, dynamic>;
  final tokenData = data['token'] as Map<String, dynamic>;
  final accessToken = tokenData['access_token'] as String;
  final refreshToken = tokenData['refresh_token'] as String;
  print('\n   ✓ access_token: ${accessToken.substring(0, 20)}...');
  print('   ✓ refresh_token: ${refreshToken.substring(0, 20)}...');
  print('   ✓ token_type: ${tokenData['token_type']}');
  print('   ✓ expires_in: ${tokenData['expires_in']}');

  // ── Test /auth/me with token ──────────────────────────────────────────────
  print('\n2. GET /auth/me (with Bearer token)');
  final meRes = await dio.get(
    '/auth/me',
    options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
  );
  print('   Status: ${meRes.statusCode}');
  print('   User data:');
  print(const JsonEncoder.withIndent('  ').convert(meRes.data));

  // ── Test /users/profile ───────────────────────────────────────────────────
  print('\n3. GET /users/profile (with Bearer token)');
  final profileRes = await dio.get(
    '/users/profile',
    options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
  );
  print('   Status: ${profileRes.statusCode}');
  print('   Profile data:');
  print(const JsonEncoder.withIndent('  ').convert(profileRes.data));

  // ── Test token refresh ────────────────────────────────────────────────────
  print('\n4. POST /auth/refresh (with refresh_token in body)');
  final refreshRes = await dio.post('/auth/refresh', data: {
    'refresh_token': refreshToken,
  });
  print('   Status: ${refreshRes.statusCode}');
  print('   Refresh response:');
  print(const JsonEncoder.withIndent('  ').convert(refreshRes.data));

  // ── Test logout ───────────────────────────────────────────────────────────
  if (refreshRes.statusCode == 200) {
    final newToken = refreshRes.data['data']['token']['access_token'] as String;
    print('\n5. POST /auth/logout (with new token)');
    final logoutRes = await dio.post(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $newToken'}),
    );
    print('   Status: ${logoutRes.statusCode}');
    print('   Response: ${logoutRes.data}');

    // Verify old token is now invalid
    print('\n6. GET /auth/me (after logout — should be 401)');
    final meAfterLogout = await dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $newToken'}),
    );
    print('   Status: ${meAfterLogout.statusCode} (expected 401)');
  }

  print('\n=== ALL AUTH TESTS COMPLETE ===');
}
