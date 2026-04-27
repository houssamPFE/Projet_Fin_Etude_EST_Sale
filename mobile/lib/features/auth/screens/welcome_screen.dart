import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Particle starfield
          CustomPaint(painter: _StarfieldPainter()),

          // Ambient radial glows
          _WelcomeBackground(size: size),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 72),

                // Hero logo
                const NexoraHeroLogo()
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.82, 0.82),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeOutBack,
                    ),

                const Spacer(),

                // Bottom content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Accédez à des experts et à l\'intelligence\nartificielle en quelques secondes.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.65,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 40),

                      NexoraGradientButton(
                        label: 'Se connecter',
                        onTap: () => context.push(AppRoutes.login),
                      )
                          .animate()
                          .fadeIn(delay: 580.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('Créer un compte'),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 680.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'En continuant, vous acceptez nos Conditions d\'utilisation',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 820.ms),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome screen background (screen-specific glow positions)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBackground extends StatelessWidget {
  final Size size;
  const _WelcomeBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.12,
          left: size.width * 0.05,
          child: BlurOrb(
            width: size.width * 0.9,
            height: size.height * 0.55,
            color: const Color(0x3D8B5CF6),
          ),
        ),
        Positioned(
          top: size.height * 0.22,
          right: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.65,
            height: size.width * 0.65,
            color: const Color(0x283B82F6),
          ),
        ),
        Positioned(
          top: size.height * 0.30,
          left: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.width * 0.55,
            color: const Color(0x226366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.08,
          left: size.width * 0.15,
          child: BlurOrb(
            width: size.width * 0.7,
            height: size.height * 0.28,
            color: const Color(0x1A6366F1),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deterministic particle dots — welcome screen only
// ─────────────────────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  static final _dots = List.generate(45, (i) {
    final rng = Random(i * 17 + 3);
    return (
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      r: rng.nextDouble() * 1.4 + 0.4,
      a: rng.nextDouble() * 0.25 + 0.04,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      canvas.drawCircle(
        Offset(d.x * size.width, d.y * size.height),
        d.r,
        Paint()..color = Colors.white.withAlpha((d.a * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
