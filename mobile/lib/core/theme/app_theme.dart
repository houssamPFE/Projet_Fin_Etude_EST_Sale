import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'theme_provider.dart';

class AppTheme {
  static ThemeData get dark => getTheme(AppThemePreset.darkPreset);

  static ThemeData getTheme(AppThemePreset preset) {
    final bool isDark = preset.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: preset.brightness,
      scaffoldBackgroundColor: preset.background,
      primaryColor: preset.primary,
      colorScheme: ColorScheme(
        brightness: preset.brightness,
        primary: preset.primary,
        onPrimary: Colors.white,
        primaryContainer: preset.primaryDark,
        onPrimaryContainer: preset.primaryLight,
        secondary: preset.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: preset.surface,
        onSurface: preset.textPrimary,
        outline: preset.border,
        outlineVariant: preset.divider,
      ),

      // Typography
      textTheme: (isDark 
          ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.interTextTheme(ThemeData.light().textTheme)
      ).copyWith(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: preset.textPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: preset.textPrimary),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: preset.textPrimary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: preset.textPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: preset.textPrimary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: preset.textPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: preset.textPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: preset.textPrimary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: preset.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: preset.textSecondary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: preset.textSecondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: preset.textTertiary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: preset.textPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: preset.textSecondary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: preset.textTertiary),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: preset.background,
        foregroundColor: preset.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: preset.background,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: preset.textPrimary),
        iconTheme: IconThemeData(
          color: preset.textPrimary,
          size: 22,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: preset.surface,
        selectedItemColor: preset.primary,
        unselectedItemColor: preset.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: preset.surface,
        indicatorColor: preset.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: preset.primary, size: 22);
          }
          return IconThemeData(color: preset.textTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: preset.primary);
          }
          return AppTextStyles.labelSmall.copyWith(color: preset.textTertiary);
        }),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: preset.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: preset.surfaceElevated,
          disabledForegroundColor: preset.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
          minimumSize: const Size(0, 50),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: preset.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: preset.textPrimary,
          side: BorderSide(color: preset.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonMedium,
          minimumSize: const Size(0, 50),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.inputHint.copyWith(color: preset.textTertiary),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: preset.textSecondary),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: preset.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: preset.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: preset.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: preset.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: preset.divider, width: 1),
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        iconColor: preset.textTertiary,
        prefixIconColor: preset.textTertiary,
        suffixIconColor: preset.textTertiary,
      ),

      // Card
      cardTheme: CardThemeData(
        color: preset.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: preset.cardBorder, width: 1),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: preset.divider,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: preset.surface,
        selectedColor: preset.primary.withValues(alpha: 0.15),
        disabledColor: preset.surface,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: preset.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: preset.border),
        ),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: preset.surfaceElevated,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: preset.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: preset.surface,
        modalBackgroundColor: preset.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: preset.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: preset.textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: preset.textSecondary),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: preset.textSecondary,
        textColor: preset.textPrimary,
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: preset.textTertiary),
        titleTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: preset.textPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return preset.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return preset.primary;
          return preset.surface;
        }),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: preset.primary,
        linearTrackColor: preset.surface,
        circularTrackColor: preset.surface,
      ),

      // Icon
      iconTheme: IconThemeData(
        color: preset.textSecondary,
        size: 20,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: preset.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: preset.primary,
        unselectedLabelColor: preset.textTertiary,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: preset.primary, width: 2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        ),
        dividerColor: preset.divider,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        color: preset.surfaceElevated,
        elevation: 8,
        shadowColor: const Color(0x80000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.bodyMedium.copyWith(color: preset.textPrimary),
      ),
    );
  }
}
