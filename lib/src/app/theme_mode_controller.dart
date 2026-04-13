import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app's [ThemeMode] and persists it across sessions.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  /// Creates a controller that reads the stored preference.
  ThemeModeController({required SharedPreferences preferences})
    : _preferences = preferences,
      super(_load(preferences));

  final SharedPreferences _preferences;
  static const _key = 'theme_mode';

  static ThemeMode _load(SharedPreferences prefs) {
    final stored = prefs.getString(_key);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Toggles between light and dark mode.
  ///
  /// When currently in [ThemeMode.system], uses [platformBrightness] to
  /// determine the opposite mode.
  void toggle(Brightness platformBrightness) {
    final next = switch (value) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system =>
        platformBrightness == Brightness.light
            ? ThemeMode.dark
            : ThemeMode.light,
    };
    value = next;
    _preferences.setString(_key, next.name);
  }
}
