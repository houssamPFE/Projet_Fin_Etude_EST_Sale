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
import '../models/auth_response.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _pwVisible = false;
  bool _cfVisible = false;
  int _currentPage = 0;

  // OTP state
  bool _showOtp = false;
  String _registeredEmail = '';
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

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

  void _goToForm() {
    _pageController.nextPage(duration: 420.ms, curve: Curves.easeInOutCubic);
    setState(() => _currentPage = 1);
  }

  void _goBack() {
    if (_showOtp) {
      setState(() => _showOtp = false);
      return;
    }
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: 380.ms, curve: Curves.easeInOutCubic);
      setState(() => _currentPage = 0);
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final email = await ref.read(authProvider.notifier).register(
          name: name,
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted || email == null) return;
    setState(() {
      _showOtp = true;
      _registeredEmail = email;
    });
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) _otpFocusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _otpFocusNodes[index - 1].requestFocus();
    setState(() {});
  }

  Future<void> _onVerifyOtp() async {
    if (_otpCode.length < 6) return;
    final ok = await ref
        .read(authProvider.notifier)
        .verifyEmail(email: _registeredEmail, code: _otpCode);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _onResendOtp() async {
    if (_resendCooldown > 0) return;
    await ref.read(authProvider.notifier).resendOtp(email: _registeredEmail);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _RegisterBackground(size: size),
          SafeArea(
            child: Column(
              children: [
                // Top bar — always show back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      NexoraBackButton(onTap: _goBack),
                      const Spacer(),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildIntro(),
                      _buildForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 0: Intro ──────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          const _RegisterHeroLogo()
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 48),

          Text(
            'Créer un compte',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.12, end: 0),

          const SizedBox(height: 12),

          Text(
            'Rejoignez Nexora et accédez à vos\nexperts de santé et à l\'IA.',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 220.ms),

          const SizedBox(height: 40),

          NexoraGradientButton(
            label: 'Commencer',
            onTap: _goToForm,
          )
              .animate()
              .fadeIn(delay: 320.ms)
              .slideY(begin: 0.12, end: 0),

          const SizedBox(height: 32),

          const OrDivider().animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 20),

          SocialAuthButton(
            brand: SocialBrand.google,
            label: 'Continuer avec Google',
            onTap: () => _onSocialLogin('google'),
          ).animate().fadeIn(delay: 460.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          SocialAuthButton(
            brand: SocialBrand.facebook,
            label: 'Continuer avec Facebook',
            onTap: () => _onSocialLogin('facebook'),
          ).animate().fadeIn(delay: 520.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 44),

          _LoginPrompt(onTap: () => Navigator.maybePop(context))
              .animate()
              .fadeIn(delay: 600.ms),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Page 1: Form (+ inline OTP) ────────────────────────────────────────────

  Widget _buildForm() {
    final authState = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Form(
        key: _formKey,
        child: AnimatedSwitcher(
          duration: 400.ms,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _showOtp ? _buildOtpSection(authState) : _buildFields(authState),
        ),
      ),
    );
  }

  Widget _buildFields(AuthState authState) {
    return Column(
      key: const ValueKey('fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        Text(
          'Informations du compte',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.25,
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 8),

        Text(
          'Remplissez vos informations pour continuer.',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF94A3B8),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 32),

        GlassTextField(
          controller: _firstNameCtrl,
          label: '',
          hint: 'Prénom',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Veuillez entrer votre prénom' : null,
        ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 14),

        GlassTextField(
          controller: _lastNameCtrl,
          label: '',
          hint: 'Nom',
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Veuillez entrer votre nom' : null,
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 14),

        GlassTextField(
          controller: _emailCtrl,
          label: '',
          hint: 'Adresse e-mail',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Veuillez entrer votre e-mail';
            if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$').hasMatch(v.trim())) {
              return 'Adresse e-mail invalide';
            }
            return null;
          },
        ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 14),

        GlassPasswordField(
          controller: _passwordCtrl,
          label: '',
          hint: 'Mot de passe',
          visible: _pwVisible,
          onToggle: () => setState(() => _pwVisible = !_pwVisible),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Veuillez créer un mot de passe';
            if (v.length < 8) return 'Minimum 8 caractères requis';
            return null;
          },
        ).animate().fadeIn(delay: 390.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 14),

        GlassPasswordField(
          controller: _confirmCtrl,
          label: '',
          hint: 'Confirmer le mot de passe',
          visible: _cfVisible,
          onToggle: () => setState(() => _cfVisible = !_cfVisible),
          textInputAction: TextInputAction.done,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Veuillez confirmer';
            if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
            return null;
          },
        ).animate().fadeIn(delay: 460.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 16),

        const _PasswordHints().animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 12),

        const _LegalNotice().animate().fadeIn(delay: 530.ms),

        if (authState.error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withAlpha(80)),
            ),
            child: Text(
              authState.error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],

        const SizedBox(height: 28),

        NexoraGradientButton(
          label: 'Créer mon compte',
          isLoading: authState.isLoading,
          onTap: _onRegister,
        ).animate().fadeIn(delay: 580.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOtpSection(AuthState authState) {
    return Column(
      key: const ValueKey('otp'),
      children: [
        const SizedBox(height: 20),

        // Illustration
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withAlpha(15),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withAlpha(150),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 44,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).scale(curve: Curves.easeOutBack),

        const SizedBox(height: 32),

        Text(
          'Vérifiez votre e-mail',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 12),

        Text(
          'Nous avons envoyé un code de\nvérification à :',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF94A3B8),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 160.ms),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withAlpha(5),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Text(
            _registeredEmail,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ).animate().fadeIn(delay: 220.ms),

        const SizedBox(height: 36),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.12, end: 0),

        if (authState.error != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withAlpha(80)),
            ),
            child: Text(
              authState.error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],

        if (authState.infoMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Text(
              authState.infoMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
        ],

        const SizedBox(height: 36),

        NexoraGradientButton(
          label: 'Vérifier',
          isLoading: authState.isLoading,
          onTap: _onVerifyOtp,
        ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.12, end: 0),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pas reçu le code ? ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
            GestureDetector(
              onTap: _resendCooldown > 0 ? null : _onResendOtp,
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
        ).animate().fadeIn(delay: 440.ms),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final focused = _otpFocusNodes[index].hasFocus;
    final filled = _otpControllers[index].text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 62,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
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
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: AppTextStyles.headlineLarge.copyWith(
            color: filled ? AppColors.primaryLight : AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
          onChanged: (v) => _onOtpDigitChanged(index, v),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register Hero Logo
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterHeroLogo extends StatelessWidget {
  const _RegisterHeroLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
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
            const NexoraImageIcon(size: 80),
          ],
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFCDD0FF), Color(0xFFFFFFFF)],
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

// ─────────────────────────────────────────────────────────────────────────────
// Password hints
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordHints extends StatelessWidget {
  const _PasswordHints();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: const [
        _Hint('Au moins 8 caractères'),
        _Hint('Une lettre majuscule'),
        _Hint('Un chiffre ou un symbole'),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String label;
  const _Hint(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal notice
// ─────────────────────────────────────────────────────────────────────────────

class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.caption,
        children: [
          const TextSpan(text: 'En créant un compte, vous acceptez nos '),
          TextSpan(
            text: 'Conditions d\'utilisation',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const TextSpan(text: ' et notre '),
          TextSpan(
            text: 'Politique de confidentialité',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login prompt
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
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
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

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterBackground extends StatelessWidget {
  final Size size;
  const _RegisterBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.06,
          left: -size.width * 0.1,
          child: BlurOrb(
            width: size.width * 0.90,
            height: size.height * 0.46,
            color: const Color(0x556366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.03,
          right: -size.width * 0.18,
          child: BlurOrb(
            width: size.width * 0.60,
            height: size.width * 0.60,
            color: const Color(0x458B5CF6),
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
