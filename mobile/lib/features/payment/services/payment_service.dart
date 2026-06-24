import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentService — wraps all payment-related API calls
// ─────────────────────────────────────────────────────────────────────────────

class PaymentService {
  const PaymentService(this._dio);

  final Dio _dio;

  // ── Stripe: create payment intent for a plan ───────────────────────────────

  /// Returns { client_secret, payment_intent_id }
  Future<Map<String, dynamic>> createStripeIntent({
    required String plan,   // 'pro' | 'premium' | 'extra'
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/payments/stripe/intent',
      data: {'plan': plan},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  /// Confirm Stripe payment after card entry
  Future<Map<String, dynamic>> confirmStripe({
    required String paymentIntentId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/payments/stripe/confirm',
      data: {'payment_intent_id': paymentIntentId},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  // ── CMI: initiate a redirect payment ──────────────────────────────────────

  /// Returns { redirect_url, order_id }
  Future<Map<String, dynamic>> initiateCmi({
    required String plan,   // 'pro' | 'premium' | 'extra'
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/payments/cmi/initiate',
      data: {'plan': plan},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  // ── Buy extra credit ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> buyExtraCredit({
    required String provider,   // 'stripe' | 'cmi'
  }) async {
    if (provider == 'cmi') {
      return initiateCmi(plan: 'extra');
    }
    return createStripeIntent(plan: 'extra');
  }

  // ── Payment history ────────────────────────────────────────────────────────

  Future<List<dynamic>> getHistory() async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/history');
    final data = res.data!['data'];
    return data is List ? data : (data as Map)['data'] as List? ?? [];
  }
}
