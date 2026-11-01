import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/app/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dark mode is remembered after the app closes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final first = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(preferences)]);
    expect(first.read(themeModeProvider), ThemeMode.light);
    first.read(themeModeProvider.notifier).setDark(true);
    first.dispose();

    final second = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(preferences)]);
    expect(second.read(themeModeProvider), ThemeMode.dark);
    second.dispose();
  });
}
