import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/auth_response.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSocialLogin(String provider) async {
    final notifier = ref.read(authProvider.notifier);
    final result = provider == 'google'
        ? await notifier.loginWithGoogle()
        : await notifier.loginWithFacebook();
    if (!mounted || result == null) return;
    switch (result) {
      case LoginSuccess():
        context.go(AppRoutes.home);
      case LoginNeeds2FA(:final twoFactorToken):
        context.push(AppRoutes.twoFactor, extra: twoFactorToken);
      case LoginNeedsVerification():
        break;
    }
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || result == null) return;

    switch (result) {
      case LoginSuccess():
        context.go(AppRoutes.home);
      case LoginNeeds2FA(:final twoFactorToken):
        context.push(AppRoutes.twoFactor, extra: twoFactorToken);
      case LoginNeedsVerification():
        context.push(AppRoutes.otp,
            extra: {'email': _emailController.text.trim()});
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
          _LoginBackground(size: size),
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
                          const SizedBox(height: 24),

                          const Center(child: _LoginHeroLogo())
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.88, 0.88),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOutBack,
                              ),

                          const SizedBox(height: 48), // Added spacing below logo to match reference

                          const _LoginHeader()
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(
                                  begin: 0.15,
                                  end: 0,
                                  curve: Curves.easeOut),

                          const SizedBox(height: 36),

                          GlassTextField(
                            controller: _emailController,
                            label: '', // Removed floating label to match reference
                            hint: 'Adresse e-mail',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer votre adresse e-mail';
                              }
                              if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$')
                                  .hasMatch(value.trim())) {
                                return 'Adresse e-mail invalide';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 250.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 16),

                          GlassPasswordField(
                            controller: _passwordController,
                            label: '', // Removed floating label to match reference
                            hint: 'Mot de passe',
                            visible: _passwordVisible,
                            onToggle: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 caractères requis';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 330.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Mot de passe oublié ?',
                                style: AppTextStyles.link,
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms),

                          if (authState.maintenance) ...[
                            const SizedBox(height: 16),
                            _MaintenanceBanner(),
                          ] else if (authState.error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: authState.error!),
                          ],

                          const SizedBox(height: 24),

                          NexoraGradientButton(
                            label: 'Se connecter',
                            isLoading: authState.isLoading,
                            onTap: _onLogin,
                          )
                              .animate()
                              .fadeIn(delay: 470.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 32),

                          const OrDivider().animate().fadeIn(delay: 580.ms),

                          const SizedBox(height: 20),

                          SocialAuthButton(
                            brand: SocialBrand.google,
                            label: 'Continuer avec Google',
                            onTap: () => _onSocialLogin('google'),
                          )
                              .animate()
                              .fadeIn(delay: 640.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 12),

                          SocialAuthButton(
                            brand: SocialBrand.facebook,
                            label: 'Continuer avec Facebook',
                            onTap: () => _onSocialLogin('facebook'),
                          )
                              .animate()
                              .fadeIn(delay: 710.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 44),

                          Center(
                            child: _SignupPrompt(
                              onTap: () => context.push(AppRoutes.register),
                            ),
                          ).animate().fadeIn(delay: 800.ms),

                          const SizedBox(height: 16),
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
// Background — vivid ambient orbs
// ─────────────────────────────────────────────────────────────────────────────

class _LoginBackground extends StatelessWidget {
  final Size size;
  const _LoginBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          left: size.width * 0.02,
          child: BlurOrb(
            width: size.width * 0.95,
            height: size.height * 0.50,
            color: const Color(0x5A8B5CF6),
          ),
        ),
        Positioned(
          top: -size.height * 0.04,
          right: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.width * 0.55,
            color: const Color(0x456366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.28,
          right: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.width * 0.55,
            color: const Color(0x306366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.05,
          left: size.width * 0.08,
          child: BlurOrb(
            width: size.width * 0.85,
            height: size.height * 0.28,
            color: const Color(0x2E6366F1),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bon retour !', style: AppTextStyles.displaySmall),
        const SizedBox(height: 10),
        Text(
          'Connectez-vous pour accéder\nà vos experts et à l\'IA.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Maintenance banner
// ─────────────────────────────────────────────────────────────────────────────

class _MaintenanceBanner extends StatelessWidget {
  const _MaintenanceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.construction_rounded,
              size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plateforme en maintenance',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nexora est temporairement indisponible. Veuillez réessayer dans quelques instants.',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFFCD34D),
                    height: 1.4,
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
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.error.withAlpha(200)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-up prompt
// ─────────────────────────────────────────────────────────────────────────────

class _SignupPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SignupPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Créer un compte',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Login Screen Hero Logo
// ─────────────────────────────────────────────────────────────────────────────

class _LoginHeroLogo extends StatelessWidget {
  const _LoginHeroLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer ambient ring
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x458B5CF6),
                    Color(0x186366F1),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Core glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(110),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            const NexoraImageIcon(size: 80), // Larger N icon to match reference
          ],
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFCDD0FF),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'N E X O R A',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect to Expertise',
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF818CF8),
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
