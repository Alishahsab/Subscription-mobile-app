import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTones {
  const AppTones(this.dark);

  final bool dark;

  Color get title => dark ? AppColors.darkTextPrimary : AppColors.navy;
  Color get border => dark ? const Color(0xFF2F3644) : const Color(0xFFE4E4E7);
  Color get faint => dark ? const Color(0xFF6C7588) : const Color(0xFFA1A1AA);
  Color get cardShadow => AppColors.navy.withValues(alpha: dark ? 0 : 0.1);

  Color get softFill => dark ? const Color(0xFF1C2440) : const Color(0xFFEEF1F7);
  Color get softText => dark ? const Color(0xFFA8BDF5) : AppColors.navy;
  Color get strongButton => dark ? AppColors.darkAccent : AppColors.navy;
  Color get neutralFill => dark ? const Color(0xFF343B4A) : const Color(0xFFEDEEF1);
  Color get neutralText => dark ? const Color(0xFFD5DAE3) : const Color(0xFF52525B);

  Color get redFill => dark ? const Color(0xFF361B1E) : const Color(0xFFFEF2F2);
  Color get redText => dark ? const Color(0xFFFBB0B0) : const Color(0xFFB91C1C);
  Color get amberFill => dark ? const Color(0xFF3A2E17) : const Color(0xFFFFFBEB);
  Color get amberText => dark ? const Color(0xFFDCBB79) : const Color(0xFFB45309);
  Color get amberLine => dark ? const Color(0xFF5C4718) : const Color(0xFFFDE68A);
  Color get redLine => dark ? const Color(0xFF5A2A2E) : const Color(0xFFFECACA);
  Color get greenChip => dark ? const Color(0xFF1F5C46) : const Color(0xFF9CE3C6);
  Color get greenChipText => dark ? const Color(0xFFBFF3DE) : const Color(0xFF022C22);
  Color get amberChip => dark ? const Color(0xFF5C4718) : const Color(0xFFFCDF7E);
  Color get amberChipText => dark ? const Color(0xFFFDE9B0) : const Color(0xFF451A03);
  Color get redChip => dark ? const Color(0xFF6B2A2C) : const Color(0xFFFFB3B3);
  Color get redChipText => dark ? const Color(0xFFFFD6D6) : const Color(0xFF450A0A);
  Color get greenFill => dark ? const Color(0xFF11261E) : const Color(0xFFECFDF5);
  Color get greenText => dark ? const Color(0xFF7FE0B8) : const Color(0xFF047857);
  Color get violetFill => dark ? const Color(0xFF221B3D) : const Color(0xFFF5F3FF);
  Color get violetText => dark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);

  Color get blueFill => dark ? const Color(0xFF10222F) : const Color(0xFFF0F9FF);
  Color get blueText => dark ? const Color(0xFF8BD0F5) : const Color(0xFF0369A1);

  Color get chatBackground => dark ? const Color(0xFF12161D) : const Color(0xFFF7F8FA);
  Color get fieldFill => dark ? const Color(0xFF1B2029) : const Color(0xFFF8F9FB);
  Color get botBubble => dark ? const Color(0xFF222A39) : const Color(0xFFE9EDF5);
  Color get botText => dark ? const Color(0xFFA9B0BE) : const Color(0xFF52525B);

  Color get chartTrack => dark ? const Color(0xFF1C2440) : const Color(0xFFEEF1F7);
  Color get chartBar => dark ? const Color(0xFF34426E) : const Color(0xFFC7D2EC);
  Color get chartPicked => dark ? const Color(0xFF5B74B3) : AppColors.navy;
}

extension AppTonesOfContext on BuildContext {
  AppTones get tones => AppTones(Theme.of(this).brightness == Brightness.dark);
}
