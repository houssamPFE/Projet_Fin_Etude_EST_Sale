import 'dart:async';
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

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
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
  }

  Future<void> _onVerify() async {
    if (_code.length < 6) return;
    final ok = await ref
        .read(authProvider.notifier)
        .verifyEmail(email: widget.email, code: _code);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _onResend() async {
    if (_resendCooldown > 0) return;
    await ref.read(authProvider.notifier).resendOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _OtpBackground(size: size),
          SafeArea(
            child: Column(
              children: [
                const NexoraBackButton().animate().fadeIn(duration: 400.ms),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // ── Email illustration ──────────────────────────────
                        const _EmailIllustration()
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(curve: Curves.easeOutBack),

                        const SizedBox(height: 32),

                        // ── Title ───────────────────────────────────────────
                        Text(
                          'Vérifiez votre e-mail',
                          style: AppTextStyles.displaySmall,
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 500.ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                        const SizedBox(height: 12),

                        Text(
                          'Nous avons envoyé un code de vérification à :',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 210.ms, duration: 500.ms),

                        const SizedBox(height: 14),

                        // ── Email badge ─────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primary.withAlpha(22),
                            border: Border.all(
                                color: AppColors.primary.withAlpha(65)),
                          ),
                          child: Text(
                            widget.email,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate().fadeIn(delay: 270.ms, duration: 400.ms),

                        const SizedBox(height: 40),

                        // ── 6-box OTP input ─────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (i) => _OtpBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              onChanged: (v) => _onDigitChanged(i, v),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 340.ms, duration: 500.ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                        if (authState.error != null) ...[
                          const SizedBox(height: 20),
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

                        if (authState.infoMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.success.withAlpha(80)),
                            ),
                            child: Text(
                              authState.infoMessage!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.success),
                            ),
                          ),
                        ],

                        const SizedBox(height: 36),

                        NexoraGradientButton(
                          label: 'Vérifier',
                          isLoading: authState.isLoading,
                          onTap: _onVerify,
                        )
                            .animate()
                            .fadeIn(delay: 430.ms, duration: 500.ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                        const SizedBox(height: 28),

                        // ── Resend row ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous n\'avez pas reçu le code ? ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _resendCooldown > 0 ? null : _onResend,
                              child: _resendCooldown > 0
                                  ? Text(
                                      'Renvoyer (${_resendCooldown}s)',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textTertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : Text(
                                      'Renvoyer le code',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 530.ms),
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
// Email illustration
// ─────────────────────────────────────────────────────────────────────────────

class _EmailIllustration extends StatelessWidget {
  const _EmailIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ambient glow
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(28),
          ),
        ),
        // Mid glow ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(70),
                blurRadius: 30,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        // Icon container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withAlpha(100),
                AppColors.primary.withAlpha(70),
              ],
            ),
            border: Border.all(
              color: Colors.white.withAlpha(35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(60),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            size: 38,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single OTP digit box
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
    final filled = widget.controller.text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 62,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: focused
              ? const Color(0x226366F1)
              : filled
                  ? const Color(0x156366F1)
                  : AppColors.surface,
          border: Border.all(
            color: focused
                ? AppColors.primary
                : filled
                    ? AppColors.primary.withAlpha(100)
                    : AppColors.border,
            width: focused ? 1.8 : 1.0,
          ),
          boxShadow: focused
              ? [
                  const BoxShadow(
                    color: Color(0x606366F1),
                    blurRadius: 20,
                    spreadRadius: -3,
                  )
                ]
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
          style: AppTextStyles.headlineMedium.copyWith(
            color: filled ? AppColors.primaryLight : AppColors.textPrimary,
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBackground extends StatelessWidget {
  final Size size;
  const _OtpBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          left: size.width * 0.03,
          child: BlurOrb(
            width: size.width * 0.92,
            height: size.height * 0.48,
            color: const Color(0x556366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.15,
          right: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.50,
            height: size.width * 0.50,
            color: const Color(0x408B5CF6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.05,
          right: size.width * 0.04,
          child: BlurOrb(
            width: size.width * 0.72,
            height: size.height * 0.26,
            color: const Color(0x2A8B5CF6),
          ),
        ),
      ],
    );
  }
}
