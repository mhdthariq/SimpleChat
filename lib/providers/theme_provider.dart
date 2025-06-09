// File: lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load the theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themePreference = prefs.getString(_themePreferenceKey);

      if (themePreference != null) {
        _themeMode =
            themePreference == 'dark'
                ? ThemeMode.dark
                : themePreference == 'light'
                ? ThemeMode.light
                : ThemeMode.system;
        notifyListeners();
      }
    } catch (e) {
      // Default to system theme if there's an error
      _themeMode = ThemeMode.system;
    }
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themePreferenceKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      // Just log the error, don't crash the app
      print('Error saving theme preference: $e');
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themePreferenceKey,
        mode == ThemeMode.dark
            ? 'dark'
            : mode == ThemeMode.light
            ? 'light'
            : 'system',
      );
    } catch (e) {
      // Just log the error, don't crash the app
      print('Error saving theme preference: $e');
    }
  }
}
