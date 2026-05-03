import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background      = Color(0xFF070B18);
  static const Color backgroundAlt   = Color(0xFF0D1120);
  static const Color surface         = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A2035);
  static const Color card            = Color(0xFF151C2E);
  static const Color cardBorder      = Color(0xFF1E2A42);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary         = Color(0xFF6366F1); // Indigo
  static const Color primaryDark     = Color(0xFF4F52D9);
  static const Color primaryLight    = Color(0xFF818CF8);
  static const Color secondary       = Color(0xFF8B5CF6); // Violet
  static const Color secondaryLight  = Color(0xFFA78BFA);
  static const Color accent          = Color(0xFF3B82F6); // Blue

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const Color gradientStart   = Color(0xFF6366F1);
  static const Color gradientMid     = Color(0xFF8B5CF6);
  static const Color gradientEnd     = Color(0xFF3B82F6);

  // ── Glow / Ambient ────────────────────────────────────────────────────────
  static const Color glowPrimary     = Color(0x406366F1);
  static const Color glowSecondary   = Color(0x408B5CF6);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFFF9FAFB);
  static const Color textSecondary   = Color(0xFF9CA3AF);
  static const Color textTertiary    = Color(0xFF6B7280);
  static const Color textDisabled    = Color(0xFF374151);
  static const Color textInverse     = Color(0xFF111827);

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
  static const Color border          = Color(0xFF1E2A42);
  static const Color borderFocus     = Color(0xFF6366F1);
  static const Color divider         = Color(0xFF1A2338);

  // ── Input ─────────────────────────────────────────────────────────────────
  static const Color inputBackground = Color(0xFF111827);
  static const Color inputBorder     = Color(0xFF1E2A42);
  static const Color inputFocused    = Color(0xFF6366F1);

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const Color overlay         = Color(0xCC070B18);
  static const Color shimmerBase     = Color(0xFF1A2035);
  static const Color shimmerHighlight= Color(0xFF1E2A42);
}
