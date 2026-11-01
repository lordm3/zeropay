import 'package:flutter/material.dart';
import 'app_colors.dart';

class Palette {
  final bool isDark;
  const Palette(this.isDark);

  factory Palette.of(BuildContext context) =>
      Palette(Theme.of(context).brightness == Brightness.dark);

  Color get surface => isDark ? AppColors.surfacePrimaryDark : AppColors.surfacePrimaryLight;
  Color get container => isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight;
  Color get inputPill => isDark ? AppColors.surfaceInputPillDark : AppColors.surfaceInputPillLight;
  Color get accent => isDark ? AppColors.primaryAccentDark : AppColors.primaryAccentLight;
  Color get onAccent => isDark ? AppColors.onPrimaryAccentDark : AppColors.onPrimaryAccentLight;
  Color get errorContainer => isDark ? AppColors.errorContainerDark : AppColors.errorContainerLight;
  Color get error => isDark ? AppColors.errorPrimaryDark : AppColors.errorPrimaryLight;
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
}
