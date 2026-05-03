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

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final ok = await ref.read(authProvider.notifier).forgotPassword(email: email);
    if (ok && mounted) {
      context.push(AppRoutes.resetPassword, extra: email);
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
          _FpBackground(size: size),
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
                          Text('Mot de passe oublié', style: AppTextStyles.displaySmall)
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 500.ms)
                              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 10),
                          Text(
                            'Entrez votre adresse e-mail. Nous vous enverrons un code de réinitialisation.',
                            style: AppTextStyles.bodyLarge,
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms),
                          const SizedBox(height: 36),
                          GlassTextField(
                            controller: _emailController,
                            label: 'Adresse e-mail',
                            hint: 'votre@email.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Veuillez entrer votre adresse e-mail';
                              }
                              if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$')
                                  .hasMatch(v.trim())) {
                                return 'Adresse e-mail invalide';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 500.ms)
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
                            label: 'Envoyer le code',
                            isLoading: authState.isLoading,
                            onTap: _onSubmit,
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 500.ms)
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

class _FpBackground extends StatelessWidget {
  final Size size;
  const _FpBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.10,
          right: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.85,
            height: size.height * 0.45,
            color: const Color(0x2A8B5CF6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.06,
          left: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.75,
            height: size.height * 0.24,
            color: const Color(0x1A6366F1),
          ),
        ),
      ],
    );
  }
}
