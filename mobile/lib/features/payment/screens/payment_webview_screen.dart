import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/current_user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentWebviewScreen — handles CMI redirect payment flow
// ─────────────────────────────────────────────────────────────────────────────

class PaymentWebviewScreen extends ConsumerStatefulWidget {
  final String url;
  final String planId;

  const PaymentWebviewScreen({
    super.key,
    required this.url,
    required this.planId,
  });

  @override
  ConsumerState<PaymentWebviewScreen> createState() =>
      _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends ConsumerState<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  // Detect success/failure from URL patterns returned by CMI callback
  static const _successPatterns = ['/payment/success', '/payment/cmi/callback'];
  static const _failurePatterns = ['/payment/fail', '/payment/failed'];

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkUrl(url);
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _checkUrl(String url) {
    // Payment success
    if (_successPatterns.any((p) => url.contains(p))) {
      // Refresh user data to pick up updated plan/credits
      ref.invalidate(currentUserProvider);
      _navigateResult(success: true);
      return;
    }

    // Payment failure
    if (_failurePatterns.any((p) => url.contains(p))) {
      _navigateResult(success: false);
    }
  }

  void _navigateResult({required bool success}) {
    if (!mounted) return;
    // Replace current route with result screen
    context.pushReplacement(
      AppRoutes.paymentResult,
      extra: {
        'success': success,
        'planId': widget.planId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const NexoraBackButton(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiement sécurisé',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 10, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'CMI · SSL',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Loading indicator in title area
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.withAlpha(180),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _hasError
          ? _ErrorView(url: widget.url, onRetry: () {
              setState(() => _hasError = false);
              _controller.loadRequest(Uri.parse(widget.url));
            })
          : WebViewWidget(controller: _controller),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String url;
  final VoidCallback onRetry;

  const _ErrorView({required this.url, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withAlpha(18),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444), size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Impossible de charger la page de paiement',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion internet et réessayez.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Text(
                  'Réessayer',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentResultScreen — shown after CMI redirect completes
// ─────────────────────────────────────────────────────────────────────────────

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String planId;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.planId,
  });

  @override
  Widget build(BuildContext context) {
    final planName = planId == 'premium' ? 'Premium' : planId == 'pro' ? 'Pro' : 'Crédit extra';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: success
                        ? const Color(0xFF10B981).withAlpha(20)
                        : const Color(0xFFEF4444).withAlpha(20),
                    border: Border.all(
                      color: success
                          ? const Color(0xFF10B981).withAlpha(60)
                          : const Color(0xFFEF4444).withAlpha(60),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    success ? Icons.check_rounded : Icons.close_rounded,
                    size: 44,
                    color: success
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  success ? 'Paiement réussi !' : 'Paiement échoué',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  success
                      ? 'Votre plan $planName est maintenant actif. Profitez de vos consultations !'
                      : 'Le paiement n\'a pas pu être traité. Veuillez réessayer ou choisir un autre mode de paiement.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Primary action
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: success
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : null,
                        color: success ? null : AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          success ? 'Aller à l\'accueil' : 'Retour à l\'accueil',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (!success) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.upgrade),
                    child: Text(
                      'Réessayer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
