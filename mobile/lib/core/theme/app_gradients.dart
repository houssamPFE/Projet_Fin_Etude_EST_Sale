import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppGradients {
  // ── Primary brand gradient ─────────────────────────────────────────────
  static LinearGradient get primary => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMid,
      AppColors.gradientEnd,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ── Vertical hero gradient (dark top to brand bottom) ──────────────────
  static LinearGradient get hero => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.background,
      AppColors.backgroundAlt,
      AppColors.surface,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ── Ambient glow (for cards and buttons) ───────────────────────────────
  static LinearGradient get cardGlow => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary.withValues(alpha: 0.1),
      AppColors.secondary.withValues(alpha: 0.04),
    ],
  );

  // ── Button gradient ────────────────────────────────────────────────────
  static LinearGradient get button => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.primary,
      AppColors.secondary,
    ],
  );

  // ── Shimmer gradient ───────────────────────────────────────────────────
  static LinearGradient get shimmer => LinearGradient(
    begin: const Alignment(-1.0, -0.3),
    end: const Alignment(1.0, 0.3),
    colors: [
      AppColors.shimmerBase,
      AppColors.shimmerHighlight,
      AppColors.shimmerBase,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ── Overlay gradient (fade to bottom for images) ───────────────────────
  static LinearGradient get imageOverlay => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      AppColors.overlay,
    ],
  );

  // ── Radial glow for avatar / icon backgrounds ──────────────────────────
  static RadialGradient get avatarGlow => RadialGradient(
    colors: [
      AppColors.primary.withValues(alpha: 0.25),
      Colors.transparent,
    ],
    radius: 0.8,
  );
}
