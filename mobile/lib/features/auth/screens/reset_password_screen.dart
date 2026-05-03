import 'package:flutter/material.dart';
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

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _codeController      = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();
  bool _passwordVisible      = false;
  bool _confirmVisible       = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).resetPassword(
          email:    widget.email,
          code:     _codeController.text.trim(),
          password: _passwordController.text,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé. Connectez-vous.')),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size      = MediaQuery.sizeOf(context);
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
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Center(child: NexoraMiniLogo())
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.88, 0.88),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 40),
                          Text('Nouveau mot de passe', style: AppTextStyles.displaySmall)
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyLarge,
                              children: [
                                const TextSpan(text: 'Code envoyé à '),
                                TextSpan(
                                  text: widget.email,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 32),

                          // ── OTP code ─────────────────────────────────────
                          GlassTextField(
                            controller: _codeController,
                            label: 'Code de vérification',
                            hint: '123456',
                            prefixIcon: Icons.lock_outline_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().length != 6) {
                                return 'Le code doit comporter 6 chiffres';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 280.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 14),

                          // ── New password ──────────────────────────────────
                          GlassPasswordField(
                            controller: _passwordController,
                            label: 'Nouveau mot de passe',
                            hint: 'Minimum 8 caractères',
                            visible: _passwordVisible,
                            onToggle: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Veuillez créer un mot de passe';
                              }
                              if (v.length < 8) {
                                return 'Minimum 8 caractères requis';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 350.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 14),

                          // ── Confirm password ──────────────────────────────
                          GlassPasswordField(
                            controller: _confirmController,
                            label: 'Confirmer le mot de passe',
                            hint: '••••••••',
                            visible: _confirmVisible,
                            onToggle: () => setState(
                              () => _confirmVisible = !_confirmVisible,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 420.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          if (authState.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.error.withAlpha(80)),
                              ),
                              child: Text(
                                authState.error!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          NexoraGradientButton(
                            label: 'Réinitialiser',
                            isLoading: authState.isLoading,
                            onTap: _onSubmit,
                          )
                              .animate()
                              .fadeIn(delay: 490.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
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

class _RpBackground extends StatelessWidget {
  final Size size;
  const _RpBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          left: -size.width * 0.15,
          child: BlurOrb(
            width: size.width * 0.85,
            height: size.height * 0.44,
            color: const Color(0x326366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.05,
          right: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.7,
            height: size.height * 0.22,
            color: const Color(0x188B5CF6),
          ),
        ),
      ],
    );
  }
}
