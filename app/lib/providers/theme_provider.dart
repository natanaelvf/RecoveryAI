import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme preference — system (follows device), dark, or light.
enum ThemePreference { system, dark, light }

/// Converts ThemePreference to Flutter's ThemeMode.
ThemeMode themeModeFromPreference(ThemePreference pref) {
  switch (pref) {
    case ThemePreference.system:
      return ThemeMode.system;
    case ThemePreference.dark:
      return ThemeMode.dark;
    case ThemePreference.light:
      return ThemeMode.light;
  }
}

/// Theme preference provider — defaults to system.
/// TODO: Persist to SharedPreferences in a later pass.
final themePreferenceProvider = StateProvider<ThemePreference>((ref) {
  return ThemePreference.system;
});
