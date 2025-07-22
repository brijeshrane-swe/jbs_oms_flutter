import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences. This must be overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'SharedPreferences provider must be overridden at the root.');
});

/// A StateNotifier that manages the font scale of the application.
class FontScaleNotifier extends StateNotifier<double> {
  final SharedPreferences _prefs;
  static const _fontScaleKey = 'app_font_scale';

  FontScaleNotifier(this._prefs) : super(1.0) {
    // Load the saved font scale when the notifier is created.
    state = _prefs.getDouble(_fontScaleKey) ?? 1.0;
  }

  /// Sets the font scale and saves it to SharedPreferences.
  Future<void> setFontScale(double newScale) async {
    // Clamp the value to a reasonable range.
    final clampedScale = newScale.clamp(0.8, 1.5);
    state = clampedScale;
    await _prefs.setDouble(_fontScaleKey, clampedScale);
  }
}

/// The main provider for accessing the FontScaleNotifier and the current font scale.
final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FontScaleNotifier(prefs);
});
