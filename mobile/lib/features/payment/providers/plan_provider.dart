import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/current_user_provider.dart';
import '../services/payment_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentService provider
// ─────────────────────────────────────────────────────────────────────────────

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(dioProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Current plan state (derived from currentUserProvider)
// ─────────────────────────────────────────────────────────────────────────────

class PlanState {
  final String plan;           // 'free' | 'pro' | 'premium'
  final int credits;
  final DateTime? expiresAt;
  final bool isActive;

  const PlanState({
    this.plan = 'free',
    this.credits = 0,
    this.expiresAt,
    this.isActive = false,
  });

  bool get isPaid => plan == 'pro' || plan == 'premium';

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    return expiresAt!.difference(DateTime.now()).inDays <= 5;
  }

  String get displayName {
    switch (plan) {
      case 'pro':     return 'Pro';
      case 'premium': return 'Premium';
      default:        return 'Gratuit';
    }
  }
}

final planStateProvider = Provider<AsyncValue<PlanState>>((ref) {
  return ref.watch(currentUserProvider).whenData(
    (user) => PlanState(
      plan: user.plan,
      credits: user.consultationCredits,
      expiresAt: user.planExpiresAt,
      isActive: user.planIsActive,
    ),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Payment intent state — used by UpgradeScreen during checkout
// ─────────────────────────────────────────────────────────────────────────────

class PaymentIntentState {
  final bool isLoading;
  final String? error;
  final String? clientSecret;
  final String? cmiRedirectUrl;

  const PaymentIntentState({
    this.isLoading = false,
    this.error,
    this.clientSecret,
    this.cmiRedirectUrl,
  });

  PaymentIntentState copyWith({
    bool? isLoading,
    String? error,
    String? clientSecret,
    String? cmiRedirectUrl,
  }) => PaymentIntentState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    clientSecret: clientSecret ?? this.clientSecret,
    cmiRedirectUrl: cmiRedirectUrl ?? this.cmiRedirectUrl,
  );
}

class PaymentIntentNotifier extends StateNotifier<PaymentIntentState> {
  PaymentIntentNotifier(this._service) : super(const PaymentIntentState());

  final PaymentService _service;

  Future<String?> initiateStripe(String plan) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.createStripeIntent(plan: plan);
      final secret = data['client_secret'] as String?;
      state = state.copyWith(isLoading: false, clientSecret: secret);
      return secret;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return null;
    }
  }

  Future<String?> initiateCmi(String plan) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.initiateCmi(plan: plan);
      final url = data['redirect_url'] as String?;
      state = state.copyWith(isLoading: false, cmiRedirectUrl: url);
      return url;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('402')) return 'Paiement refusé. Vérifiez vos informations.';
      if (msg.contains('422')) return 'Données invalides. Veuillez réessayer.';
      if (msg.contains('503')) return 'Service temporairement indisponible.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}

final paymentIntentProvider =
    StateNotifierProvider<PaymentIntentNotifier, PaymentIntentState>((ref) {
  return PaymentIntentNotifier(ref.read(paymentServiceProvider));
});
