import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme(); // load saved theme
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      if (_themeMode == ThemeMode.system) notifyListeners();
    };
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefKey, _themeMode.name);
  }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_prefKey);
    _themeMode = (saved == 'dark')
        ? ThemeMode.dark
        : (saved == 'light')
            ? ThemeMode.light
            : ThemeMode.system;
    notifyListeners();
  }
}
