import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.lightColorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
        surfaceTintColor: Colors.transparent,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.lightText,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.lightText,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.lightText,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.lightText,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.lightText,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.lightText,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.lightText,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.lightText,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.lightText,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.lightText,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.lightText,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),

      // Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge.copyWith(
            color: Colors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.lightText,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.lightSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.lightText,
        textColor: AppColors.lightText,
        subtitleTextStyle: TextStyle(
          color: AppColors.lightTextSecondary,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.lightText,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightText,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.lightTextSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.lightBorder;
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.darkColorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
        surfaceTintColor: Colors.transparent,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.darkText,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.darkText,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.darkText,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.darkText,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkText,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.darkText,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.darkText,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.darkText,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.darkText,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkText,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkText,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge.copyWith(
            color: Colors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.accent,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.accent,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkText,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.darkSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.darkText,
        textColor: AppColors.darkText,
        subtitleTextStyle: TextStyle(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.darkText,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkText,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accent;
          }
          return AppColors.darkTextSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accent.withOpacity(0.3);
          }
          return AppColors.darkBorder;
        }),
      ),
    );
  }
}
