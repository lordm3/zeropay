import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfacePrimaryDark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surfacePrimaryDark,
        primary: AppColors.primaryAccentDark,
        onPrimary: AppColors.onPrimaryAccentDark,
        error: AppColors.errorPrimaryDark,
        errorContainer: AppColors.errorContainerDark,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfacePrimaryLight,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surfacePrimaryLight,
        primary: AppColors.primaryAccentLight,
        onPrimary: AppColors.onPrimaryAccentLight,
        error: AppColors.errorPrimaryLight,
        errorContainer: AppColors.errorContainerLight,
      ),
    );
  }
}
