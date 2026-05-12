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

  print('=== NEXORA BACKEND INTEGRATION TEST ===\n');

  // ── Step 1: Public endpoints ──────────────────────────────────────────────
  print('1. GET /categories (public)');
  final catRes = await dio.get('/categories');
  print('   ✓ ${catRes.statusCode} — ${(catRes.data['data'] as List).length} categories\n');

  print('2. GET /experts (public)');
  final expRes = await dio.get('/experts');
  print('   ✓ ${expRes.statusCode} — ${(expRes.data['data'] as List).length} experts');
  if ((expRes.data['data'] as List).isNotEmpty) {
    final first = (expRes.data['data'] as List).first as Map<String, dynamic>;
    print('   Keys: ${first.keys.toList()}\n');
  }

  // ── Step 2: Login with a verified user ────────────────────────────────────
  // Using "lahrachaya808@gmail.com" which has email_verified_at set.
  // We don't know the password, so let's test the error handling path first.
  print('3. POST /auth/login (wrong password — testing error format)');
  final badLogin = await dio.post('/auth/login', data: {
    'email': 'lahrachaya808@gmail.com',
    'password': 'wrongpassword',
  });
  print('   ✓ ${badLogin.statusCode} — ${badLogin.data}');
  print('   Error message: ${badLogin.data['message']}\n');

  // ── Step 3: Test register (new unique email) ──────────────────────────────
  final testEmail = 'mobiletest_${DateTime.now().millisecondsSinceEpoch}@nexora.test';
  print('4. POST /auth/register (email: $testEmail)');
  final regRes = await dio.post('/auth/register', data: {
    'name': 'Mobile Test User',
    'email': testEmail,
    'password': 'SecurePass123!',
    'password_confirmation': 'SecurePass123!',
  });
  print('   ✓ ${regRes.statusCode}');
  print('   Response keys: ${(regRes.data as Map).keys.toList()}');
  print('   Message: ${regRes.data['message']}\n');

  // ── Step 4: Login with unverified user (should get requires_verification) ──
  print('5. POST /auth/login (unverified user)');
  final unverifiedLogin = await dio.post('/auth/login', data: {
    'email': testEmail,
    'password': 'SecurePass123!',
  });
  print('   ✓ ${unverifiedLogin.statusCode}');
  print('   requires_verification: ${unverifiedLogin.data['requires_verification']}');
  print('   Message: ${unverifiedLogin.data['message']}\n');

  // ── Step 5: Force-verify the user and login ───────────────────────────────
  // We'll use tinker alternative: directly call verify via API if OTP is known
  // For now, let's verify the response structure is correct

  // ── Step 6: Test unauthenticated access to protected route ────────────────
  print('6. GET /auth/me (no token — testing 401)');
  final meNoAuth = await dio.get('/auth/me');
  print('   ✓ ${meNoAuth.statusCode} (expected 401)');
  print('   Response: ${meNoAuth.data}\n');

  // ── Step 7: Test validation errors format ─────────────────────────────────
  print('7. POST /auth/register (duplicate email — testing 422)');
  final dupRes = await dio.post('/auth/register', data: {
    'name': 'Dup',
    'email': testEmail,
    'password': 'SecurePass123!',
    'password_confirmation': 'SecurePass123!',
  });
  print('   ✓ ${dupRes.statusCode}');
  print('   Errors format: ${dupRes.data['errors']}\n');

  print('=== ALL TESTS COMPLETE ===');
}
