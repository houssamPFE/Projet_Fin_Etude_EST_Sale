import 'package:flutter/material.dart';
import 'theme_provider.dart';

abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static Color get background      => AppThemePreset.current.background;
  static Color get backgroundAlt   => AppThemePreset.current.backgroundAlt;
  static Color get surface         => AppThemePreset.current.surface;
  static Color get surfaceElevated => AppThemePreset.current.surfaceElevated;
  static Color get card            => AppThemePreset.current.card;
  static Color get cardBorder      => AppThemePreset.current.cardBorder;

  // ── Brand ─────────────────────────────────────────────────────────────────
  static Color get primary         => AppThemePreset.current.primary;
  static Color get primaryDark     => AppThemePreset.current.primaryDark;
  static Color get primaryLight    => AppThemePreset.current.primaryLight;
  static Color get secondary       => AppThemePreset.current.secondary;
  static Color get secondaryLight  => AppThemePreset.current.secondaryLight;
  static Color get accent          => AppThemePreset.current.accent;

  // ── Gradients ─────────────────────────────────────────────────────────────
  static Color get gradientStart   => AppThemePreset.current.primary;
  static Color get gradientMid     => AppThemePreset.current.secondary;
  static Color get gradientEnd     => AppThemePreset.current.accent;

  // ── Glow / Ambient ────────────────────────────────────────────────────────
  static Color get glowPrimary     => AppThemePreset.current.primary.withValues(alpha: 0.25);
  static Color get glowSecondary   => AppThemePreset.current.secondary.withValues(alpha: 0.25);

  // ── Text ──────────────────────────────────────────────────────────────────
  static Color get textPrimary     => AppThemePreset.current.textPrimary;
  static Color get textSecondary   => AppThemePreset.current.textSecondary;
  static Color get textTertiary    => AppThemePreset.current.textTertiary;
  static Color get textDisabled    => AppThemePreset.current.brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);
  static Color get textInverse     => AppThemePreset.current.brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success         = Color(0xFF10B981);
  static const Color successBg       = Color(0xFF052E1C);
  static const Color warning         = Color(0xFFF59E0B);
  static const Color warningBg       = Color(0xFF2D1F02);
  static const Color error           = Color(0xFFEF4444);
  static const Color errorBg         = Color(0xFF2D0A0A);
  static const Color info            = Color(0xFF0EA5E9);
  static const Color infoBg          = Color(0xFF052032);

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static Color get border          => AppThemePreset.current.border;
  static Color get borderFocus     => AppThemePreset.current.primary;
  static Color get divider         => AppThemePreset.current.divider;

  // ── Input ─────────────────────────────────────────────────────────────────
  static Color get inputBackground => AppThemePreset.current.surface;
  static Color get inputBorder     => AppThemePreset.current.border;
  static Color get inputFocused    => AppThemePreset.current.primary;

  // ── Overlay ───────────────────────────────────────────────────────────────
  static Color get overlay         => AppThemePreset.current.brightness == Brightness.dark ? const Color(0xCC070B18) : const Color(0xCCFDFCEB);
  static Color get shimmerBase     => AppThemePreset.current.surfaceElevated;
  static Color get shimmerHighlight=> AppThemePreset.current.border;
}
