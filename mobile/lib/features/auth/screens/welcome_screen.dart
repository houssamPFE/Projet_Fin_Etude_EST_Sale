import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _totalPages - 1;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!isFirstPage) {
          _goToPrevPage();
        } else {
          await SystemNavigator.pop();
          exit(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _WelcomeBackground(size: size),
            const _AnimatedStarfield(),

            SafeArea(
              child: Column(
                children: [

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(
                        parent: PageScrollPhysics(),
                      ),
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: const [
                        _HeroPage(),
                        _ExpertsPage(),
                        _SecurityPage(),
                        _AIPage(),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isFirstPage ? 0.0 : 1.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _currentPage == index
                                  ? AppColors.primaryLight
                                  : Colors.white.withAlpha(50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NexoraGradientButton(
                          label: (isFirstPage || isLastPage) ? 'Commencer' : 'Suivant',
                          onTap: () {
                            if (isLastPage) {
                              context.push(AppRoutes.login);
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: (isFirstPage || isLastPage) ? 48 : 0,
                          alignment: Alignment.bottomCenter,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 260),
                            opacity: (isFirstPage || isLastPage) ? 1.0 : 0.0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Déjà un compte ? ',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push(AppRoutes.login),
                                    child: Text(
                                      'Se connecter',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPage extends StatelessWidget {
  const _HeroPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),

          const _OnboardingHeroLogo()
              .animate()
              .fadeIn(duration: 900.ms)
              .scale(
                begin: const Offset(0.82, 0.82),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),

          const Spacer(flex: 2),

          Text(
            'Votre santé, augmentée\npar l\'intelligence artificielle.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFB0B7C3) : AppColors.textSecondary,
              height: 1.5,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.08, end: 0),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ExpertsPage extends StatelessWidget {
  const _ExpertsPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),

          _ChatIllustration(isDark: isDark)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                  begin: const Offset(0.88, 0.88),
                  curve: Curves.easeOutBack),

          const Spacer(flex: 2),

          Text(
            'Des experts\nà portée de main',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          Text(
            'Consultez des médecins qualifiés\nvia messagerie sécurisée.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _SecurityPage extends StatelessWidget {
  const _SecurityPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),

          _ShieldIllustration(isDark: isDark)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                  begin: const Offset(0.88, 0.88),
                  curve: Curves.easeOutBack),

          const Spacer(flex: 2),

          Text(
            'Sécurisé &\nConfidentiel',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          Text(
            'Vos données sont protégées avec\nles plus hauts standards de\nsécurité.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _AIPage extends StatelessWidget {
  const _AIPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),

          _PhoneIllustration(isDark: isDark)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                  begin: const Offset(0.88, 0.88),
                  curve: Curves.easeOutBack),

          const Spacer(flex: 2),

          Text(
            'IA à vos côtés\n24h/24',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          Text(
            'Notre IA vous aide à mieux\ncomprendre votre santé et vous oriente.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding hero logo — screen 1 centrepiece (stronger glow than shared widget)
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingHeroLogo extends StatelessWidget {
  const _OnboardingHeroLogo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background glow, closely hugging the logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF3B82F6) : AppColors.primary).withAlpha(100), // dynamic glow
                      blurRadius: 35, // smaller blur
                      spreadRadius: 5,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOut,
                  ),

              // N icon — luminance filter removes dark background, matrix maps to green/mint in light mode
              ColorFiltered(
                colorFilter: isDark
                    ? const ColorFilter.matrix([
                        1, 0, 0, 0, 0,
                        0, 1, 0, 0, 0,
                        0, 0, 1, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                      ])
                    : const ColorFilter.matrix([
                        0.1, 0.0, 0.1, 0, 0,
                        0.6, 0.8, 0.6, 0, 0,
                        0.3, 0.2, 0.3, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                      ]),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // NEXORA wordmark
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? const [
                    Color(0xFFFFFFFF),
                    Color(0xFFE2E8F0),
                    Color(0xFFFFFFFF),
                  ]
                : [
                    AppColors.textPrimary,
                    AppColors.textPrimary.withAlpha(200),
                    AppColors.textPrimary,
                  ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'N E X O R A',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tagline with decorative lines
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GradientLine(toRight: false),
            const SizedBox(width: 8),
            Text(
              'Intelligence & Santé',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            _GradientLine(toRight: true),
          ],
        ),
      ],
    );
  }
}

class _GradientLine extends StatelessWidget {
  final bool toRight;
  const _GradientLine({required this.toRight});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
          end: toRight ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            isDark ? const Color(0xFF3B82F6) : AppColors.primary,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brain illustration — CustomPainter brain shape with pink/purple gradient
// ─────────────────────────────────────────────────────────────────────────────

class _ChatIllustration extends StatelessWidget {
  final bool isDark;
  const _ChatIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient soft glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF2563EB) : const Color(0xFF10B981)).withAlpha(40),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          
          // Outer glass sphere
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (isDark ? const Color(0xFF3B82F6) : AppColors.primary).withAlpha(60),
                width: 1.5,
              ),
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF3B82F6) : AppColors.primary).withAlpha(10),
                  (isDark ? const Color(0xFF2563EB) : AppColors.primary).withAlpha(25),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF34D399)).withAlpha(15),
                  blurRadius: 20,
                  spreadRadius: -10,
                )
              ],
            ),
          ),

          // Back Chat Bubble
          Positioned(
            top: 55,
            right: 45,
            child: Container(
              width: 90,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? const Color(0xFF1D4ED8) : const Color(0xFF00A566)).withAlpha(160),
                    (isDark ? const Color(0xFF2563EB) : const Color(0xFF10B981)).withAlpha(120),
                  ],
                ),
                border: Border.all(
                  color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF34D399)).withAlpha(70),
                  width: 1,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: -2, end: 2, duration: 2500.ms, curve: Curves.easeInOut),
          ),

          // Front Chat Bubble
          Positioned(
            bottom: 55,
            left: 35,
            child: CustomPaint(
              painter: _ChatBubblePainter(isDark: isDark),
              child: SizedBox(
                width: 120,
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // offset for the tail
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(),
                        const SizedBox(width: 8),
                        _Dot(),
                        const SizedBox(width: 8),
                        _Dot(),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: 2, end: -2, duration: 2800.ms, curve: Curves.easeInOut),
          ),

          // Floating Badges
          Positioned(
            top: 5,
            left: 5,
            child: _FloatingIconBadge(
              icon: Icons.grid_view_rounded,
              color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF10B981), // green/blue
              size: 38,
              delay: 0,
            ),
          ),
          Positioned(
            top: 10,
            right: 4,
            child: _FloatingIconBadge(
              icon: Icons.person_rounded,
              color: isDark ? const Color(0xFF6366F1) : AppColors.primary,
              size: 38,
              delay: 700,
            ),
          ),
          Positioned(
            bottom: 5,
            left: 4,
            child: _FloatingIconBadge(
              icon: Icons.chat_bubble_rounded,
              color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF059669),
              size: 36,
              delay: 350,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 5,
            child: _FloatingIconBadge(
              icon: Icons.group_rounded,
              color: isDark ? const Color(0xFF6366F1) : const Color(0xFF10B981),
              size: 36,
              delay: 1050,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF93C5FD) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF34D399)).withAlpha(150),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  final bool isDark;
  const _ChatBubblePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tailSize = 16.0;
    final radius = 20.0;

    Path bubblePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h - tailSize), Radius.circular(radius)));
          
    Path tailPath = Path()
      ..moveTo(radius + 18, h - tailSize)
      ..lineTo(radius - 2, h - 2)
      ..quadraticBezierTo(radius + 2, h - tailSize * 0.5, radius + 8, h - tailSize)
      ..close();
      
    final path = Path.combine(PathOperation.union, bubblePath, tailPath);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF60A5FA), // light blue
                Color(0xFF2563EB), // blue
                Color(0xFF1D4ED8), // dark blue
              ]
            : [
                const Color(0xFF34D399),
                AppColors.primary,
                const Color(0xFF059669),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Subtle border
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF93C5FD), Color(0xFF3B82F6)]
            : [const Color(0xFF34D399), AppColors.primary],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter oldDelegate) => oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shield illustration — gradient shield + lock + floating badges
// ─────────────────────────────────────────────────────────────────────────────

class _ShieldIllustration extends StatelessWidget {
  final bool isDark;
  const _ShieldIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient soft glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF00A566)).withAlpha(40),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          
          // Outer glass sphere
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF10B981)).withAlpha(60),
                width: 1.5,
              ),
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF34D399)).withAlpha(10),
                  (isDark ? const Color(0xFF4F46E5) : const Color(0xFF00A566)).withAlpha(25),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF34D399)).withAlpha(15),
                  blurRadius: 20,
                  spreadRadius: -10,
                )
              ],
            ),
          ),

          // Shield with gradient and lock
          SizedBox(
            width: 110,
            height: 130,
            child: CustomPaint(
              painter: _ShieldPainter(isDark: isDark),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF00A566)).withAlpha(40),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withAlpha(110),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1.03, 1.03),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeInOut,
              ),

          // Floating Badges
          Positioned(
            top: 15,
            left: 15,
            child: _FloatingIconBadge(
              icon: Icons.psychology_rounded,
              color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF00A566),
              size: 40,
              delay: 200,
            ),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: _FloatingIconBadge(
              icon: Icons.group_rounded,
              color: isDark ? const Color(0xFF6366F1) : const Color(0xFF10B981),
              size: 40,
              delay: 800,
            ),
          ),
          Positioned(
            bottom: 25,
            right: 25,
            child: _FloatingIconBadge(
              icon: Icons.admin_panel_settings_rounded,
              color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF059669),
              size: 42,
              delay: 500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final bool isDark;
  const _ShieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    final shield = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.17)
      ..lineTo(w, h * 0.54)
      ..cubicTo(w, h * 0.76, w * 0.76, h * 0.91, w * 0.5, h)
      ..cubicTo(w * 0.24, h * 0.91, 0, h * 0.76, 0, h * 0.54)
      ..lineTo(0, h * 0.17)
      ..close();

    // Gradient fill — indigo/purple
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF4F46E5).withAlpha(100), // indigo
                  const Color(0xFF6366F1).withAlpha(75),  // indigo lighter
                  const Color(0xFF8B5CF6).withAlpha(55),  // purple
                ]
              : [
                  const Color(0xFF00A566).withAlpha(100),
                  const Color(0xFF10B981).withAlpha(75),
                  const Color(0xFF34D399).withAlpha(55),
                ],
        ).createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // Glow stroke — purple/indigo
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF8B5CF6), Color(0xFF6366F1)]
              : [const Color(0xFF34D399), const Color(0xFF00A566)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Crisp border
    canvas.drawPath(
      shield,
      Paint()
        ..color = (isDark ? const Color(0xFF818CF8) : const Color(0xFF10B981)).withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner highlight line at top
    canvas.drawLine(
      Offset(w * 0.25, h * 0.09),
      Offset(w * 0.75, h * 0.09),
      Paint()
        ..color = Colors.white.withAlpha(40)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) => oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone illustration — glassmorphic phone + chat UI + floating icons
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneIllustration extends StatelessWidget {
  final bool isDark;
  const _PhoneIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        clipBehavior: Clip.none, // Allow badges to overlap outside the bounds safely
        alignment: Alignment.center,
        children: [
          // Subtle ambient glow behind phone
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withAlpha(60),
                  blurRadius: 70,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF00A566)).withAlpha(40),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: const Duration(milliseconds: 3000),
                curve: Curves.easeInOut,
              ),

          // Phone body
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-0.25) // reduced rotation
              ..rotateX(0.05)
              ..rotateZ(-0.02),
            alignment: Alignment.center,
            child: Container(
              width: 125,
              height: 220, // Slightly reduced height to prevent overflow issues
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF334155).withAlpha(240), // Brighter slate for visibility
                    const Color(0xFF0F172A).withAlpha(255), // slate-900
                  ],
                ),
                border: Border.all(
                  color: (isDark ? const Color(0xFF3B82F6) : AppColors.primary).withAlpha(160), // dynamic edge
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : AppColors.primary).withAlpha(50),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notch
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(200),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header skeleton
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(25),
                          ),
                          child: const Icon(Icons.person, size: 14, color: Colors.white54),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 5,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // List items matching the reference design (reduced to 3 to fix overflow)
                    _PhoneListItem(iconColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
                    const SizedBox(height: 10),
                    _PhoneListItem(iconColor: isDark ? const Color(0xFF6366F1) : AppColors.primary, width: 70),
                    const SizedBox(height: 10),
                    _PhoneListItem(iconColor: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF34D399)),
                  ],
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: -4, end: 4, duration: 3500.ms, curve: Curves.easeInOut),

          // Floating Badge Left (Chat)
          Positioned(
            top: 45,
            left: -5,
            child: _GlassChatBadge(
              icon: Icons.forum_rounded,
              iconColor: Colors.white,
              color: isDark ? const Color(0xFF4F46E5) : const Color(0xFF00A566),
              tailLeft: false, // Tail points to bottom-right
              delay: 0,
            ),
          ),

          // Floating Badge Right (Heart)
          Positioned(
            bottom: 30,
            right: -10,
            child: _GlassChatBadge(
              icon: Icons.favorite_rounded,
              iconColor: isDark ? const Color(0xFFF472B6) : Colors.white,
              color: isDark ? const Color(0xFFDB2777) : const Color(0xFF10B981),
              size: 56, // Slightly reduced to fit gracefully
              tailLeft: true, // Tail points to bottom-left
              delay: 800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneListItem extends StatelessWidget {
  final Color iconColor;
  final double width;

  const _PhoneListItem({required this.iconColor, this.width = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withAlpha(40),
              border: Border.all(color: iconColor.withAlpha(120), width: 1),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(90),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3,
                  width: width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(1.5),
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

class _GlassChatBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color color;
  final double size;
  final int delay;
  final bool tailLeft;

  const _GlassChatBadge({
    required this.icon,
    required this.iconColor,
    required this.color,
    this.size = 50,
    this.delay = 0,
    this.tailLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.85,
      decoration: BoxDecoration(
        color: color.withAlpha(45),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomRight: tailLeft ? const Radius.circular(16) : const Radius.circular(4),
          bottomLeft: tailLeft ? const Radius.circular(4) : const Radius.circular(16),
        ),
        border: Border.all(
          color: color.withAlpha(130),
          width: 1.5, 
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(70),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .moveY(begin: -5, end: 5, duration: Duration(milliseconds: 2500 + delay), delay: Duration(milliseconds: delay), curve: Curves.easeInOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating icon badge — used in all illustrations
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final int delay;

  const _FloatingIconBadge({
    required this.icon,
    required this.color,
    this.size = 44,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27), // rounded-square (iOS icon style)
        color: color.withAlpha(22),
        border: Border.all(color: color.withAlpha(90), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(35),
            color.withAlpha(12),
          ],
        ),
      ),
      child: Icon(icon, size: size * 0.44, color: color.withAlpha(230)),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: -8,
          duration: Duration(milliseconds: 1800 + (delay % 600)),
          delay: Duration(milliseconds: delay),
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background — strong central indigo/violet atmosphere
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBackground extends StatelessWidget {
  final Size size;
  const _WelcomeBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // Background Waves
          Positioned.fill(
            child: CustomPaint(
              painter: _GlowingWavesPainter(isDark: isDark),
            ),
          ),
          // Deep subtle glows in the corners to avoid washing out the center
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: BlurOrb(
              width: size.width * 0.8,
              height: size.height * 0.4,
              color: isDark ? const Color(0x151D4ED8) : const Color(0x1A00A566), // dynamic orbs
              sigma: 120,
            ),
          ),
          Positioned(
            bottom: size.height * 0.2,
            left: -size.width * 0.2,
            child: BlurOrb(
              width: size.width * 0.8,
              height: size.height * 0.4,
              color: isDark ? const Color(0x0A2563EB) : const Color(0x1210B981), // dynamic orbs
              sigma: 100,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingWavesPainter extends CustomPainter {
  final bool isDark;
  const _GlowingWavesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    void drawWave(double yOffset, double amplitude, double phase, Color color, double width, double blur) {
      final path = Path();
      path.moveTo(0, yOffset);
      for (double x = 0; x <= w; x += 5) {
        final y = yOffset + amplitude * math.sin((x / w) * math.pi * 2 + phase);
        path.lineTo(x, y);
      }
      
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
      
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withAlpha(200)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.3,
      );
    }

    // Draw a few overlapping waves in the middle-bottom (around the text area)
    final centerY = h * 0.58;
    if (isDark) {
      drawWave(centerY - 10, 25, 0.0, const Color(0xFF2563EB).withAlpha(25), 2.5, 10);
      drawWave(centerY + 5, 30, 2.0, const Color(0xFF38BDF8).withAlpha(20), 1.5, 8);
      drawWave(centerY, 15, 4.0, const Color(0xFF4F46E5).withAlpha(15), 4, 15);
      drawWave(centerY + 20, 25, 1.0, const Color(0xFF3B82F6).withAlpha(15), 2, 8);
    } else {
      drawWave(centerY - 10, 25, 0.0, const Color(0xFF10B981).withAlpha(25), 2.5, 10);
      drawWave(centerY + 5, 30, 2.0, const Color(0xFF34D399).withAlpha(20), 1.5, 8);
      drawWave(centerY, 15, 4.0, const Color(0xFF00A566).withAlpha(15), 4, 15);
      drawWave(centerY + 20, 25, 1.0, const Color(0xFF059669).withAlpha(15), 2, 8);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingWavesPainter oldDelegate) => oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated twinkling starfield
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedStarfield extends StatefulWidget {
  const _AnimatedStarfield();

  @override
  State<_AnimatedStarfield> createState() => _AnimatedStarfieldState();
}

class _AnimatedStarfieldState extends State<_AnimatedStarfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context2, child) => CustomPaint(
        size: Size.infinite,
        painter: _StarfieldPainter(progress: _controller.value),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double progress;

  static final _dots = List.generate(55, (i) {
    final rng = math.Random(i * 37 + 11);
    return (
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      r: rng.nextDouble() * 1.4 + 0.3,
      base: rng.nextDouble() * 0.20 + 0.04,
      phase: rng.nextDouble(),
    );
  });

  const _StarfieldPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      final t = (d.phase + progress) % 1.0;
      final alpha = d.base * (0.38 + 0.62 * math.sin(t * math.pi * 2));
      canvas.drawCircle(
        Offset(d.x * size.width, d.y * size.height),
        d.r,
        Paint()..color = Colors.white.withAlpha((alpha * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.progress != progress;
}
