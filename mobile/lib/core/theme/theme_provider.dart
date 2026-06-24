import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  cream,  // Default (Off-white/Cream background + Mint Green accent)
  dark    // Sombre
}

class AppThemePreset {
  static AppThemePreset current = AppThemePreset.creamPreset;

  final AppThemeMode mode;
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color secondaryLight;
  final Color accent;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color divider;
  final Brightness brightness;

  const AppThemePreset({
    required this.mode,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.accent,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.brightness,
  });

  static final darkPreset = AppThemePreset(
    mode: AppThemeMode.dark,
    name: 'Sombre',
    primary: const Color(0xFF6366F1), // Indigo
    primaryDark: const Color(0xFF4F52D9),
    primaryLight: const Color(0xFF818CF8),
    secondary: const Color(0xFF8B5CF6), // Violet
    secondaryLight: const Color(0xFFA78BFA),
    accent: const Color(0xFF3B82F6), // Blue
    background: const Color(0xFF070B18),
    backgroundAlt: const Color(0xFF0D1120),
    surface: const Color(0xFF111827),
    surfaceElevated: const Color(0xFF1A2035),
    card: const Color(0xFF151C2E),
    cardBorder: const Color(0xFF1E2A42),
    textPrimary: const Color(0xFFF9FAFB),
    textSecondary: const Color(0xFF9CA3AF),
    textTertiary: const Color(0xFF6B7280),
    border: const Color(0xFF1E2A42),
    divider: const Color(0xFF1A2338),
    brightness: Brightness.dark,
  );

  static final creamPreset = AppThemePreset(
    mode: AppThemeMode.cream,
    name: 'Menthe Pure',
    primary: const Color(0xFF00A566), // Emerald primary
    primaryDark: const Color(0xFF008753),
    primaryLight: const Color(0xFF00A566),
    secondary: const Color(0xFF0D9488), // Teal secondary
    secondaryLight: const Color(0xFF059669), // Emerald
    accent: const Color(0xFF00A566),
    background: const Color(0xFFF2F9F6), // Soft mint background
    backgroundAlt: const Color(0xFFE3F2ED),
    surface: const Color(0xFFE3F2ED), // Slightly darker mint for cards
    surfaceElevated: const Color(0xFFD3EAE1),
    card: const Color(0xFFE3F2ED),
    cardBorder: const Color(0xFFC4E2D6),
    textPrimary: const Color(0xFF092D20), // Deep forest green text
    textSecondary: const Color(0xFF1A4C3A),
    textTertiary: const Color(0xFF4D7D6C),
    border: const Color(0xFFC4E2D6),
    divider: const Color(0xFFC4E2D6),
    brightness: Brightness.light,
  );
}

class ThemeNotifier extends StateNotifier<AppThemePreset> {
  ThemeNotifier() : super(AppThemePreset.creamPreset) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? AppThemeMode.cream.index;
    if (themeIndex == AppThemeMode.dark.index) {
      state = AppThemePreset.darkPreset;
    } else {
      state = AppThemePreset.creamPreset;
    }
    AppThemePreset.current = state;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    if (mode == AppThemeMode.dark) {
      state = AppThemePreset.darkPreset;
    } else {
      state = AppThemePreset.creamPreset;
    }
    AppThemePreset.current = state;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemePreset>((ref) {
  return ThemeNotifier();
});
