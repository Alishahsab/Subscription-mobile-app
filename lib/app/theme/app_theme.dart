import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return _theme(
      ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
      ),
      AppColors.background,
    );
  }

  static ThemeData get dark {
    return _theme(
      ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        brightness: Brightness.dark,
        primary: AppColors.darkAccent,
        onPrimary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextMuted,
      ),
      AppColors.darkBackground,
    );
  }

  static ThemeData _theme(ColorScheme colors, Color background) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    );
    return theme.copyWith(textTheme: GoogleFonts.plusJakartaSansTextTheme(theme.textTheme));
  }
}
