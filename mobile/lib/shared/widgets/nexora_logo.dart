import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Raw N icon — Image Asset
// ─────────────────────────────────────────────────────────────────────────────

class NexoraImageIcon extends StatelessWidget {
  final double size;
  const NexoraImageIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColorFiltered(
      colorFilter: isDark
          ? const ColorFilter.matrix([
              1, 0, 0, 0, 0,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
            ])
          : const ColorFilter.matrix([
              0, 0, 0, 0, 0,       // R = 0
              0.647, 0, 0, 0, 0,   // G = 0.647 (165 / 255)
              0.400, 0, 0, 0, 0,   // B = 0.400 (102 / 255)
              0.2126, 0.7152, 0.0722, 0, 0, // Alpha
            ]),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO LOGO — Welcome screen centrepiece
// Large icon + multi-ring breathing glow + NEXORA wordmark + tagline
// ─────────────────────────────────────────────────────────────────────────────

class NexoraHeroLogo extends StatelessWidget {
  const NexoraHeroLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon + glow stack ──────────────────────────────────────────────
        SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outermost slow-pulsing halo
              Container(
                width: 230,
                height: 230,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x358B5CF6),
                      Color(0x156366F1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.86, 0.86),
                    end: const Offset(1.14, 1.14),
                    duration: 3000.ms,
                    curve: Curves.easeInOut,
                  )
                  .fade(begin: 0.45, end: 1.0, duration: 3000.ms),

              // Mid pulsing ring (slightly faster phase)
              Container(
                width: 168,
                height: 168,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x556366F1),
                      Color(0x206366F1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.91, 0.91),
                    end: const Offset(1.09, 1.09),
                    duration: 2100.ms,
                    curve: Curves.easeInOut,
                  ),

              // Inner hard glow — gives the "core light" effect
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(100),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withAlpha(60),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),

              // Logo icon
              const NexoraImageIcon(size: 100),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── NEXORA wordmark ────────────────────────────────────────────────
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFCDD0FF),
              Color(0xFF818CF8),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'N E X O R A',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Tagline with decorative lines ──────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LineDivider(toRight: false),
            const SizedBox(width: 12),
            Text(
              'Intelligence & Santé',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight,
                letterSpacing: 2.8,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            _LineDivider(toRight: true),
          ],
        ),
      ],
    );
  }
}

class _LineDivider extends StatelessWidget {
  final bool toRight;
  const _LineDivider({required this.toRight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
              toRight ? Alignment.centerLeft : Alignment.centerRight,
          end: toRight ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [Color(0xFF8B5CF6), Colors.transparent],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI LOGO — Auth screens (login, register, otp, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class NexoraMiniLogo extends StatelessWidget {
  const NexoraMiniLogo({super.key});

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
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x458B5CF6),
                    Color(0x1E6366F1),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Core glow
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const NexoraImageIcon(size: 62),
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
            'NEXORA',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Connect to Expertise',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primaryLight,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL LOGO — AppBars and headers
// ─────────────────────────────────────────────────────────────────────────────

class NexoraSmallLogo extends StatelessWidget {
  final bool showText;
  const NexoraSmallLogo({super.key, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(60),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const NexoraImageIcon(size: 26),
          ],
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'NEXORA',
            style: AppTextStyles.headlineSmall.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}
