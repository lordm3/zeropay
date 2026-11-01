import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Color avatarColorFor(String name) {
  if (name.isEmpty) return AppColors.avatarPalette[0];
  final idx = name.codeUnitAt(0) % AppColors.avatarPalette.length;
  return AppColors.avatarPalette[idx];
}
