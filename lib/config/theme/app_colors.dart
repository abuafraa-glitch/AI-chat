import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightBorder = Color(0xFFEEEEEE);
  
  // Dark Mode Colors
  static const darkBackground = Color(0xFF0F0F0F);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);
  static const darkBorder = Color(0xFF333333);
  
  // Brand Colors
  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);
  
  // Accent Colors
  static const accent = Color(0xFF06B6D4); // Cyan
  static const accentLight = Color(0xFF22D3EE);
  static const accentDark = Color(0xFF0891B2);
  
  // Status Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  // Text Colors
  static const lightText = Color(0xFF1F2937);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const darkText = Color(0xFFE5E7EB);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  
  // Gradients
  static const gradientStart = Color(0xFF6366F1);
  static const gradientEnd = Color(0xFF06B6D4);
  
  // Glassmorphism
  static const glassLight = Color(0xFFFFFFFF);
  static const glassDark = Color(0xFF1A1A1A);
}

class AppColorScheme {
  static ColorScheme lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    tertiary: AppColors.primaryLight,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AppColors.lightText,
    onSurface: AppColors.lightText,
    onError: Colors.white,
  );

  static ColorScheme darkColorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    tertiary: AppColors.primaryLight,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AppColors.darkText,
    onSurface: AppColors.darkText,
    onError: Colors.white,
  );
}
