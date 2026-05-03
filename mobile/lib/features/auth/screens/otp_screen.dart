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
  final _focusNodes  = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
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
    final size      = MediaQuery.sizeOf(context);
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
                        Text('Vérification email', style: AppTextStyles.displaySmall)
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
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 40),

                        // ── 6-box OTP input ───────────────────────────────
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

                        if (authState.infoMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
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
                          child: GestureDetector(
                            onTap: _resendCooldown > 0 ? null : _onResend,
                            child: Text(
                              _resendCooldown > 0
                                  ? 'Renvoyer dans ${_resendCooldown}s'
                                  : 'Renvoyer le code',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _resendCooldown > 0
                                    ? AppColors.textTertiary
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
    return SizedBox(
      width: 44,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: focused
              ? const Color(0x1A6366F1)
              : AppColors.surface,
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
          top: -size.height * 0.10,
          left: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.9,
            height: size.height * 0.45,
            color: const Color(0x326366F1),
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
