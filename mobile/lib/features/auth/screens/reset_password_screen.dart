import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _onResend() async {
    await ref.read(authProvider.notifier).forgotPassword(email: widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien renvoyé !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _RpBackground(size: size),
          SafeArea(
            child: Column(
              children: [
                const NexoraBackButton().animate().fadeIn(duration: 400.ms),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // ── Sent illustration ────────────────────────────
                          const _SentIllustration()
                              .animate()
                              .fadeIn(duration: 700.ms)
                              .scale(curve: Curves.easeOutBack),

                          const SizedBox(height: 32),

                          Text(
                            'Vérifiez votre e-mail',
                            style: AppTextStyles.displaySmall,
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(
                                  begin: 0.12,
                                  end: 0,
                                  curve: Curves.easeOut),

                          const SizedBox(height: 12),

                          Text(
                            'Nous avons envoyé un lien de\nréinitialisation à :',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 210.ms, duration: 500.ms),

                          const SizedBox(height: 14),

                          // ── Email badge ──────────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withAlpha(5), // very subtle
                              border: Border.all(
                                  color: Colors.white.withAlpha(20)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ).animate().fadeIn(delay: 270.ms, duration: 400.ms),

                          const SizedBox(height: 24),

                          Text(
                            'Le lien est valable pendant 15 minutes.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 320.ms),

                          const SizedBox(height: 48),

                          // ── Resend Button (Outline) ──────────────────────
                          GestureDetector(
                            onTap: _onResend,
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white.withAlpha(25),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Renvoyer le lien',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF818CF8), // Purple/Indigo tint
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 380.ms),

                          const SizedBox(height: 24),

                          // ── Return to login ──────────────────────────────
                          GestureDetector(
                            onTap: () {
                              context.go(AppRoutes.login);
                            },
                            child: const Text(
                              'Retour à la connexion',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                          ).animate().fadeIn(delay: 440.ms),

                          Text(
                            'Le lien est valable pendant 15 minutes.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 640.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sent / paper-plane illustration
// ─────────────────────────────────────────────────────────────────────────────

class _SentIllustration extends StatelessWidget {
  const _SentIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8B5CF6).withAlpha(15),
          ),
        ),
        // Glow shadow ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(50),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        // Icon container — circle with outline gradient
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: const Color(0xFF8B5CF6).withAlpha(150), // Purple border
              width: 1.5,
            ),
            boxShadow: [
              // Inner ambient
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(20),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.send_outlined,
            size: 46,
            color: Color(0xFFC4B5FD), // Light purple icon
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _RpBackground extends StatelessWidget {
  final Size size;
  const _RpBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.06,
          left: -size.width * 0.12,
          child: BlurOrb(
            width: size.width * 0.88,
            height: size.height * 0.46,
            color: const Color(0x526366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.06,
          right: -size.width * 0.22,
          child: BlurOrb(
            width: size.width * 0.58,
            height: size.width * 0.58,
            color: const Color(0x403B82F6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          right: size.width * 0.04,
          child: BlurOrb(
            width: size.width * 0.72,
            height: size.height * 0.24,
            color: const Color(0x228B5CF6),
          ),
        ),
      ],
    );
  }
}
