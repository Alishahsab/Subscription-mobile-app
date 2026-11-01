import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _darkModeKey = 'dark_mode';

final preferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final dark = ref.read(preferencesProvider).getBool(_darkModeKey) ?? false;
    return dark ? ThemeMode.dark : ThemeMode.light;
  }

  void setDark(bool dark) {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    ref.read(preferencesProvider).setBool(_darkModeKey, dark);
  }
}
