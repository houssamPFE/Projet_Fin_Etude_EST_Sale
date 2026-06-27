import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/plan_model.dart';
import '../providers/plan_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UpgradeScreen — plan selection + payment provider choice
// ─────────────────────────────────────────────────────────────────────────────

class UpgradeScreen extends ConsumerStatefulWidget {
  /// If set, a banner is shown explaining why the user was redirected here.
  final String? reason;   // 'no_plan' | 'no_credits' | null

  const UpgradeScreen({super.key, this.reason});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  PlanTier _selected = PlanTier.pro;     // default selection
  bool _showProviderSheet = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final planAsync = ref.watch(planStateProvider);
    final payState = ref.watch(paymentIntentProvider);

    final currentPlan = planAsync.valueOrNull?.plan ?? 'free';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.3,
            child: BlurOrb(
              width: size.width * 0.8,
              height: size.width * 0.8,
              color: const Color(0x188B5CF6),
            ),
          ),
          Positioned(
            bottom: size.height * 0.15,
            left: -size.width * 0.25,
            child: BlurOrb(
              width: size.width * 0.6,
              height: size.width * 0.6,
              color: const Color(0x123B82F6),
            ),
          ),

          // Main scroll content
          CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const NexoraBackButton(),
                        const Spacer(),
                        Text(
                          'Choisir un plan',
                          style: AppTextStyles.titleMedium,
                        ),
                        const Spacer(),
                        const SizedBox(width: 38), // balance
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Redirect reason banner ────────────────────────────
                      if (widget.reason != null) ...[
                        _ReasonBanner(reason: widget.reason!),
                        const SizedBox(height: 20),
                      ],

                      // ── Header ────────────────────────────────────────────
                      Text(
                        'Consultez un médecin',
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez le plan qui correspond à vos besoins médicaux.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                      const SizedBox(height: 28),

                      // ── Plan cards ────────────────────────────────────────
                      ...kPlans.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final plan = entry.value;
                        final isCurrent = plan.id == currentPlan;
                        final isSelected = plan.tier == _selected;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            isSelected: isSelected,
                            isCurrent: isCurrent,
                            onTap: plan.isFree ? null : () => setState(() => _selected = plan.tier),
                          ).animate()
                            .fadeIn(delay: Duration(milliseconds: 80 + idx * 80), duration: 350.ms)
                            .slideY(begin: 0.15, end: 0),
                        );
                      }),

                      const SizedBox(height: 8),

                      // ── Extra credit note ─────────────────────────────────
                      _ExtraCreditNote(
                        onBuy: () => _showPaymentSheet(context, 'extra'),
                      ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                      const SizedBox(height: 28),

                      // ── Disclaimer ────────────────────────────────────────
                      _Disclaimer(),

                      SizedBox(height: 100 + bottom),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Sticky bottom CTA ──────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _StickyCtaBar(
              selectedPlan: _selected,
              isLoading: payState.isLoading,
              onSubscribe: () => _showPaymentSheet(context, _selected == PlanTier.pro ? 'pro' : 'premium'),
            ),
          ),

          // ── Payment provider sheet ─────────────────────────────────────────
          if (_showProviderSheet)
            _PaymentSheetBarrier(onDismiss: () => setState(() => _showProviderSheet = false)),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, String planId) {
    // Plan cards are only tappable for paid plans, but double check
    if (planId == 'free') return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaymentProviderSheet(
        planId: planId,
        onStripe: () {
          Navigator.pop(context);
          _handleStripe(planId);
        },
        onCmi: () {
          Navigator.pop(context);
          _handleCmi(context, planId);
        },
      ),
    );
  }

  Future<void> _handleStripe(String planId) async {
    // In a real integration: use flutter_stripe to collect card + confirm
    // For now: create intent and show success/fail based on response
    final secret = await ref.read(paymentIntentProvider.notifier).initiateStripe(planId);
    if (!mounted) return;

    if (secret != null) {
      // TODO S23: integrate flutter_stripe package for card sheet
      // For now, show a "coming soon" message
      _showSnack('Paiement Stripe bientôt disponible. Utilisez CMI en attendant.', isError: false);
    } else {
      final err = ref.read(paymentIntentProvider).error;
      if (err != null) _showSnack(err, isError: true);
    }
  }

  Future<void> _handleCmi(BuildContext context, String planId) async {
    final url = await ref.read(paymentIntentProvider.notifier).initiateCmi(planId);
    if (!mounted) return;

    if (url != null) {
      context.push(
        AppRoutes.paymentWebview,
        extra: {'url': url, 'planId': planId},
      );
    } else {
      final err = ref.read(paymentIntentProvider).error;
      if (err != null) _showSnack(err, isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reason banner
// ─────────────────────────────────────────────────────────────────────────────

class _ReasonBanner extends StatelessWidget {
  final String reason;
  const _ReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    final isNoCredits = reason == 'no_credits';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNoCredits
            ? const Color(0xFFF59E0B).withAlpha(18)
            : const Color(0xFF8B5CF6).withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNoCredits
              ? const Color(0xFFF59E0B).withAlpha(60)
              : const Color(0xFF8B5CF6).withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNoCredits ? Icons.warning_amber_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: isNoCredits ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isNoCredits
                  ? 'Vous n\'avez plus de crédits de consultation. Choisissez un plan pour continuer.'
                  : 'Les consultations médicales nécessitent un abonnement Pro ou Premium.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = plan.isFree && !isCurrent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? plan.accentColor.withAlpha(18)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? plan.accentColor.withAlpha(160)
                : isDisabled
                    ? AppColors.border.withAlpha(60)
                    : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected && plan.highlighted
              ? [
                  BoxShadow(
                    color: plan.accentColor.withAlpha(45),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: plan.accentColor.withAlpha(22),
                  ),
                  child: Icon(
                    _iconFor(plan.tier),
                    size: 20,
                    color: plan.accentColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.surfaceElevated
                                  : plan.accentColor.withAlpha(22),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.border
                                    : plan.accentColor.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              isCurrent ? 'Actuel' : plan.badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? AppColors.textTertiary
                                    : plan.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      plan.isFree
                          ? Text(
                              'Gratuit',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: plan.accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${plan.price.toStringAsFixed(0)} MAD',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: plan.accentColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '/ mois',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),

                // Select indicator
                if (!plan.isFree)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? plan.accentColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? plan.accentColor : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                        : null,
                  ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Credits highlight (non-free only)
            if (!plan.isFree) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: plan.accentColor.withAlpha(14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services_outlined, size: 14, color: plan.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      '${plan.credits} consultation${plan.credits > 1 ? 's' : ''} médecin / mois',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: plan.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Features list
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: plan.isFree
                        ? AppColors.textTertiary
                        : plan.accentColor.withAlpha(180),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: AppTextStyles.caption.copyWith(
                        color: plan.isFree
                            ? AppColors.textTertiary
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PlanTier tier) {
    switch (tier) {
      case PlanTier.free:    return Icons.bolt_outlined;
      case PlanTier.pro:     return Icons.bolt_rounded;
      case PlanTier.premium: return Icons.workspace_premium_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extra credit note
// ─────────────────────────────────────────────────────────────────────────────

class _ExtraCreditNote extends StatelessWidget {
  final VoidCallback onBuy;
  const _ExtraCreditNote({required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D9488).withAlpha(20),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              size: 18, color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crédits épuisés ?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Achetez une consultation supplémentaire à 89 MAD',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0D9488).withAlpha(60)),
              ),
              child: Text(
                'Acheter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disclaimer
// ─────────────────────────────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Informations importantes',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Les informations fournies ne remplacent pas une consultation médicale. '
            'En cas d\'urgence, appelez le 141 (SAMU Maroc) ou rendez-vous aux urgences. '
            'Abonnements renouvelés mensuellement. Annulation possible à tout moment.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky CTA bar
// ─────────────────────────────────────────────────────────────────────────────

class _StickyCtaBar extends StatelessWidget {
  final PlanTier selectedPlan;
  final bool isLoading;
  final VoidCallback onSubscribe;

  const _StickyCtaBar({
    required this.selectedPlan,
    required this.isLoading,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final plan = kPlans.firstWhere((p) => p.tier == selectedPlan);

    if (plan.isFree) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withAlpha(80))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan ${plan.name}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${plan.price.toStringAsFixed(0)} MAD / mois • ${plan.credits} consultations',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: isLoading ? null : onSubscribe,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: isLoading ? null : AppGradients.button,
                    color: isLoading ? AppColors.border : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : Text(
                          'S\'abonner',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment provider bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentProviderSheet extends StatelessWidget {
  final String planId;
  final VoidCallback onStripe;
  final VoidCallback onCmi;

  const _PaymentProviderSheet({
    required this.planId,
    required this.onStripe,
    required this.onCmi,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final plan = kPlans.firstWhere((p) => p.id == planId,
        orElse: () => kPlans.first);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Choisir un mode de paiement',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Plan ${plan.name} — ${plan.price.toStringAsFixed(0)} MAD / mois',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Stripe
          _ProviderTile(
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFF6772E5),
            iconBg: const Color(0x156772E5),
            title: 'Stripe',
            subtitle: 'Carte bancaire internationale (Visa, Mastercard)',
            onTap: onStripe,
          ),
          const SizedBox(height: 10),

          // CMI
          _ProviderTile(
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0x1510B981),
            title: 'CMI',
            subtitle: 'Carte bancaire marocaine (CIH, Banque Populaire, etc.)',
            onTap: onCmi,
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(
                'Paiement sécurisé SSL',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProviderTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PaymentSheetBarrier extends StatelessWidget {
  final VoidCallback onDismiss;
  const _PaymentSheetBarrier({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(color: Colors.black.withAlpha(100)),
    );
  }
}
