import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nexora N icon — custom painter
// ─────────────────────────────────────────────────────────────────────────────

class NexoraIconPainter extends CustomPainter {
  const NexoraIconPainter();

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C6FF), Color(0xFF6366F1), Color(0xFF8B5CF6)],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.22;
    final shader = _gradient.createShader(Rect.fromLTWH(0, 0, w, h));
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;

    // Left vertical bar
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(sw, 0)
        ..lineTo(sw, h)
        ..lineTo(0, h)
        ..close(),
      paint,
    );

    // Diagonal bar
    final dw = sw * 0.88;
    canvas.drawPath(
      Path()
        ..moveTo(sw * 0.55, 0)
        ..lineTo(sw * 0.55 + dw, 0)
        ..lineTo(w - sw * 0.55, h)
        ..lineTo(w - sw * 0.55 - dw, h)
        ..close(),
      paint,
    );

    // Right bar with distinctive wave hook
    canvas.drawPath(
      Path()
        ..moveTo(w - sw, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.40)
        ..cubicTo(w, h * 0.72, w * 0.72, h, w * 0.58, h)
        ..lineTo(w * 0.46, h)
        ..cubicTo(w * 0.62, h * 0.94, w - sw, h * 0.70, w - sw, h * 0.40)
        ..lineTo(w - sw, 0)
        ..close(),
      paint,
    );

    // White glowing dot at top
    final dotX = w * 0.495;
    final dotY = sw * 0.38;
    final dotR = sw * 0.21;
    canvas.drawCircle(
      Offset(dotX, dotY),
      dotR * 2.4,
      Paint()
        ..color = const Color(0x40FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(Offset(dotX, dotY), dotR, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact logo — N icon + NEXORA wordmark + tagline
// Used on Login and Register screens
// ─────────────────────────────────────────────────────────────────────────────

class NexoraMiniLogo extends StatelessWidget {
  const NexoraMiniLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x428B5CF6),
                    Color(0x1A6366F1),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x5E6366F1), Colors.transparent],
                ),
              ),
            ),
            const SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(painter: NexoraIconPainter()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFCDD0FF), Colors.white],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'NEXORA',
            style: AppTextStyles.titleLarge.copyWith(
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
// Full hero logo — large N icon + wordmark + tagline
// Used on the Welcome Screen
// ─────────────────────────────────────────────────────────────────────────────

class NexoraHeroLogo extends StatelessWidget {
  const NexoraHeroLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 172,
              height: 172,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x4A8B5CF6),
                    Color(0x1A6366F1),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x706366F1), Colors.transparent],
                ),
              ),
            ),
            const SizedBox(
              width: 74,
              height: 74,
              child: CustomPaint(painter: NexoraIconPainter()),
            ),
          ],
        ),
        const SizedBox(height: 26),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFCDD0FF),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'NEXORA',
            style: AppTextStyles.displaySmall.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 9,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connect to Expertise',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryLight,
            letterSpacing: 2.4,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
