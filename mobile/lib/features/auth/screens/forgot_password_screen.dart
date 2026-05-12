import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final ok =
        await ref.read(authProvider.notifier).forgotPassword(email: email);
    if (ok && mounted) {
      context.push(AppRoutes.resetPassword, extra: email);
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
          _FpBackground(size: size),
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

                          // ── Lock illustration ───────────────────────────
                          const _LockIllustration()
                              .animate()
                              .fadeIn(duration: 700.ms)
                              .scale(curve: Curves.easeOutBack),

                          const SizedBox(height: 36),

                          // ── Headlines ───────────────────────────────────
                          Text(
                            'Pas de souci !',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
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
                            'Entrez votre adresse e-mail et nous vous\nenverrons un lien pour réinitialiser votre\nmot de passe.',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 220.ms, duration: 500.ms),

                          const SizedBox(height: 40),

                          GlassTextField(
                            controller: _emailController,
                            label: '', // Hidden floating label
                            hint: 'Adresse e-mail', // Placeholder
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Veuillez entrer votre adresse e-mail';
                              }
                              if (!RegExp(
                                      r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$')
                                  .hasMatch(v.trim())) {
                                return 'Adresse e-mail invalide';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 320.ms, duration: 500.ms)
                              .slideY(
                                  begin: 0.12,
                                  end: 0,
                                  curve: Curves.easeOut),

                          if (authState.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.error.withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      size: 16,
                                      color: AppColors.error.withAlpha(200)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.error!,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 36),

                          NexoraGradientButton(
                            label: 'Envoyer le lien',
                            isLoading: authState.isLoading,
                            onTap: _onSubmit,
                          )
                              .animate()
                              .fadeIn(delay: 420.ms, duration: 500.ms)
                              .slideY(
                                  begin: 0.12,
                                  end: 0,
                                  curve: Curves.easeOut),

                          const SizedBox(height: 28),

                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) context.pop();
                            },
                            child: Text(
                              'Retour à la connexion',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ).animate().fadeIn(delay: 510.ms),
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
// Lock illustration
// ─────────────────────────────────────────────────────────────────────────────

class _LockIllustration extends StatelessWidget {
  const _LockIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ambient glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withAlpha(25),
          ),
        ),
        // Glow shadow ring
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withAlpha(80),
                blurRadius: 36,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Icon container — rounded square
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1).withAlpha(160),
                const Color(0xFF8B5CF6).withAlpha(100),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF818CF8).withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withAlpha(80),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              // Inner light
              BoxShadow(
                color: Colors.white.withAlpha(20),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded, // Simple lock icon matching reference
            size: 42,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _FpBackground extends StatelessWidget {
  final Size size;
  const _FpBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          right: -size.width * 0.18,
          child: BlurOrb(
            width: size.width * 0.90,
            height: size.height * 0.48,
            color: const Color(0x508B5CF6),
          ),
        ),
        Positioned(
          top: size.height * 0.05,
          left: -size.width * 0.15,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.width * 0.55,
            color: const Color(0x406366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.05,
          left: size.width * 0.06,
          child: BlurOrb(
            width: size.width * 0.78,
            height: size.height * 0.26,
            color: const Color(0x2A6366F1),
          ),
        ),
      ],
    );
  }
}
