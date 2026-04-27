import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
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

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (ok && mounted) context.go(AppRoutes.home);
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

                          const _LoginHeader()
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 36),

                          GlassTextField(
                            controller: _emailController,
                            label: 'Adresse e-mail',
                            hint: 'votre@email.com',
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
                            label: 'Mot de passe',
                            hint: '••••••••',
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
                              onPressed: () {
                                // TODO: navigate to ForgotPasswordScreen
                              },
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

                          const OrDivider().animate().fadeIn(delay: 560.ms),

                          const SizedBox(height: 20),

                          SocialAuthButton(
                            brand: SocialBrand.google,
                            label: 'Continuer avec Google',
                            onTap: () {
                              // TODO: Google OAuth
                            },
                          )
                              .animate()
                              .fadeIn(delay: 620.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 12),

                          SocialAuthButton(
                            brand: SocialBrand.facebook,
                            label: 'Continuer avec Facebook',
                            onTap: () {
                              // TODO: Facebook OAuth
                            },
                          )
                              .animate()
                              .fadeIn(delay: 690.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 44),

                          Center(
                            child: _SignupPrompt(
                              onTap: () => context.push(AppRoutes.register),
                            ),
                          ).animate().fadeIn(delay: 780.ms),

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
// Screen-specific background — glow positions tuned for login layout
// ─────────────────────────────────────────────────────────────────────────────

class _LoginBackground extends StatelessWidget {
  final Size size;
  const _LoginBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.10,
          left: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.9,
            height: size.height * 0.48,
            color: const Color(0x3A8B5CF6),
          ),
        ),
        Positioned(
          top: size.height * 0.30,
          right: -size.width * 0.3,
          child: BlurOrb(
            width: size.width * 0.6,
            height: size.width * 0.6,
            color: const Color(0x1E3B82F6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.06,
          left: size.width * 0.1,
          child: BlurOrb(
            width: size.width * 0.8,
            height: size.height * 0.26,
            color: const Color(0x1A6366F1),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen-specific header text
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
          'Connectez-vous pour accéder à vos experts et à l\'IA.',
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-up prompt — links to RegisterScreen
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
