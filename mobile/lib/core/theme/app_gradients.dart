import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppGradients {
  // ── Primary brand gradient ─────────────────────────────────────────────
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMid,
      AppColors.gradientEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Vertical hero gradient (dark top to brand bottom) ──────────────────
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF070B18),
      Color(0xFF0D1120),
      Color(0xFF111827),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Ambient glow (for cards and buttons) ───────────────────────────────
  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A6366F1),
      Color(0x0A8B5CF6),
    ],
  );

  // ── Button gradient ────────────────────────────────────────────────────
  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.primary,
      AppColors.secondary,
    ],
  );

  // ── Shimmer gradient ───────────────────────────────────────────────────
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [
      AppColors.shimmerBase,
      AppColors.shimmerHighlight,
      AppColors.shimmerBase,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Overlay gradient (fade to bottom for images) ───────────────────────
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC070B18),
    ],
  );

  // ── Radial glow for avatar / icon backgrounds ──────────────────────────
  static const RadialGradient avatarGlow = RadialGradient(
    colors: [
      Color(0x406366F1),
      Colors.transparent,
    ],
    radius: 0.8,
  );
}
