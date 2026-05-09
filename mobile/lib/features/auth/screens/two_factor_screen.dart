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

class TwoFactorScreen extends ConsumerStatefulWidget {
  final String twoFactorToken;
  const TwoFactorScreen({super.key, required this.twoFactorToken});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    // Auto-submit when all 6 digits are filled
    if (index == 5 && value.length == 1 && _code.length == 6) {
      _onVerify();
    }
  }

  Future<void> _onVerify() async {
    if (_code.length < 6) return;
    // Clear any previous error
    ref.read(authProvider.notifier);
    final ok = await ref.read(authProvider.notifier).verify2fa(
          twoFactorToken: widget.twoFactorToken,
          code: _code,
        );
    if (ok && mounted) context.go(AppRoutes.home);
    if (!ok && mounted) {
      // Clear digits so user can retry immediately
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
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
          _TfBackground(size: size),
          SafeArea(
            child: Column(
              children: [
                const NexoraBackButton().animate().fadeIn(duration: 400.ms),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
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
                        Text('Authentification 2FA', style: AppTextStyles.displaySmall)
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 500.ms)
                            .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                        const SizedBox(height: 10),
                        Text(
                          'Entrez le code à 6 chiffres de votre application Google Authenticator.',
                          style: AppTextStyles.bodyLarge,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 48),

                        // ── 6-box TOTP input ──────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) => _OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onDigitChanged(i, v),
                          )),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                        if (authState.error != null) ...[
                          const SizedBox(height: 20),
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
                          label: 'Vérifier',
                          isLoading: authState.isLoading,
                          onTap: _onVerify,
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 500.ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Le code se renouvelle toutes les 30 secondes.',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
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
// Reusable digit box (same style as OTP screen)
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return SizedBox(
      width: 44,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: focused ? const Color(0x1A6366F1) : AppColors.surface,
          border: Border.all(
            color: focused ? AppColors.primary : AppColors.border,
            width: focused ? 1.5 : 1,
          ),
          boxShadow: focused
              ? [const BoxShadow(color: Color(0x506366F1), blurRadius: 16, spreadRadius: -4)]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: AppTextStyles.headlineMedium,
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class _TfBackground extends StatelessWidget {
  final Size size;
  const _TfBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.10,
          left: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.9,
            height: size.height * 0.45,
            color: const Color(0x2A6366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.06,
          right: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.7,
            height: size.height * 0.24,
            color: const Color(0x1A8B5CF6),
          ),
        ),
      ],
    );
  }
}
