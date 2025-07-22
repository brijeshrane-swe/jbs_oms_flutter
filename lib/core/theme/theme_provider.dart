import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'font_scale_provider.dart'; // We need the sharedPreferencesProvider from here

/// Enum to represent the available theme modes.
enum AppThemeMode { light, dark, system }

/// A StateNotifier that manages the theme mode of the application.
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;
  static const _themeModeKey = 'app_theme_mode';

  ThemeModeNotifier(this._prefs) : super(AppThemeMode.system) {
    // Load the theme when the app starts.
    _loadThemeFromPreferences();
  }

  /// Loads the theme from SharedPreferences. If no theme is set,
  /// it defaults to AppThemeMode.system.
  void _loadThemeFromPreferences() {
    // Try to get the manually saved theme mode as a string.
    final savedMode = _prefs.getString(_themeModeKey);

    // If a theme was manually set, use it.
    if (savedMode == 'light') {
      state = AppThemeMode.light;
      return;
    }
    if (savedMode == 'dark') {
      state = AppThemeMode.dark;
      return;
    }

    // If no theme has been manually set (e.g., first app launch),
    // default to following the system theme.
    state = AppThemeMode.system;
  }

  /// Sets the theme mode and saves it to SharedPreferences, so it's remembered
  /// across app sessions.
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    // Persist the user's manual selection.
    await _prefs.setString(_themeModeKey, mode.name);
  }
}

/// The provider for the ThemeModeNotifier.
final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// A derived provider that converts our custom AppThemeMode into Flutter's ThemeMode.
/// The UI should watch this provider to get the final ThemeMode value.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeModeNotifierProvider);
  switch (appThemeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      // This tells the MaterialApp to automatically use the light or dark theme
      // based on the device's current settings.
      return ThemeMode.system;
  }
});
