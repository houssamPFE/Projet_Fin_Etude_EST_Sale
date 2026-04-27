import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || !ok) return;
    final msg = ref.read(authProvider).infoMessage ??
        'Compte créé. Vérifiez votre email pour confirmer votre inscription.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _RegisterBackground(size: size),
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

                          const SizedBox(height: 36),

                          const _RegisterHeader()
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 32),

                          GlassTextField(
                            controller: _nameController,
                            label: 'Nom complet',
                            hint: 'Prénom et nom',
                            prefixIcon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer votre nom complet';
                              }
                              if (value.trim().split(' ').length < 2) {
                                return 'Entrez votre prénom et votre nom';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 230.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 14),

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
                              .fadeIn(delay: 300.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 14),

                          GlassPasswordField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            hint: 'Minimum 8 caractères',
                            visible: _passwordVisible,
                            onToggle: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez créer un mot de passe';
                              }
                              if (value.length < 8) {
                                return 'Minimum 8 caractères requis';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 370.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 14),

                          GlassPasswordField(
                            controller: _confirmController,
                            label: 'Confirmer le mot de passe',
                            hint: '••••••••',
                            visible: _confirmVisible,
                            onToggle: () => setState(
                              () => _confirmVisible = !_confirmVisible,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer votre mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 440.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 12),

                          const _LegalNotice().animate().fadeIn(delay: 500.ms),

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

                          const SizedBox(height: 28),

                          NexoraGradientButton(
                            label: 'Créer un compte',
                            isLoading: authState.isLoading,
                            onTap: _onRegister,
                          )
                              .animate()
                              .fadeIn(delay: 540.ms, duration: 500.ms)
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 32),

                          const OrDivider().animate().fadeIn(delay: 620.ms),

                          const SizedBox(height: 20),

                          SocialAuthButton(
                            brand: SocialBrand.google,
                            label: 'Continuer avec Google',
                            onTap: () {
                              // TODO: Google OAuth
                            },
                          )
                              .animate()
                              .fadeIn(delay: 680.ms)
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
                              .fadeIn(delay: 740.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 44),

                          Center(
                            child: _LoginPrompt(
                              onTap: () => Navigator.maybePop(context),
                            ),
                          ).animate().fadeIn(delay: 820.ms),

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
// Screen-specific background — glows offset differently from login
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterBackground extends StatelessWidget {
  final Size size;
  const _RegisterBackground({required this.size});

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
          top: size.height * 0.04,
          right: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.58,
            height: size.width * 0.58,
            color: const Color(0x2A8B5CF6),
          ),
        ),
        Positioned(
          top: size.height * 0.38,
          left: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.width * 0.55,
            color: const Color(0x1C3B82F6),
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

// ─────────────────────────────────────────────────────────────────────────────
// Screen-specific header text
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rejoignez Nexora !', style: AppTextStyles.displaySmall),
        const SizedBox(height: 10),
        Text(
          'Créez votre compte et accédez à des experts qualifiés.',
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal notice with highlighted links
// ─────────────────────────────────────────────────────────────────────────────

class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.caption,
        children: const [
          TextSpan(text: 'En créant un compte, vous acceptez nos '),
          TextSpan(
            text: 'Conditions d\'utilisation',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(text: ' et notre '),
          TextSpan(
            text: 'Politique de confidentialité',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(text: '.'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login prompt — goes back to LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Déjà un compte ? ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Se connecter',
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
