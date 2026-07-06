// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary     = Color(0xFF2E7D32); // hijau utama
  static const primaryLight= Color(0xFF60AD5E);
  static const primaryDark = Color(0xFF005005);
  static const accent      = Color(0xFFFF8F00); // amber aksen

  static const green  = Color(0xFF4CAF50);
  static const yellow = Color(0xFFFFC107);
  static const red    = Color(0xFFF44336);

  static const background = Color(0xFFF5F7F5);
  static const surface    = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const border        = Color(0xFFE0E0E0);

  /// Warning level → color
  static Color warningColor(String level) {
    switch (level) {
      case 'red':    return red;
      case 'yellow': return yellow;
      default:       return green;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3:     true,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor:      AppColors.primary,
      primary:        AppColors.primary,
      secondary:      AppColors.accent,
      background:     AppColors.background,
      surface:        AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation:       0,
      centerTitle:     true,
      titleTextStyle:  TextStyle(

        fontSize:   18,
        fontWeight: FontWeight.w600,
        color:      AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize:     const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
  
          fontSize:   16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color:        AppColors.surface,
      elevation:    0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
    ),
  );
}
