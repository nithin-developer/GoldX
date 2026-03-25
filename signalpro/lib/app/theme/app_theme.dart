import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displaySmall: const TextStyle(fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.success,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      dividerColor: AppColors.border,
      cardColor: AppColors.surface,
      useMaterial3: true,
    );
  }
}
