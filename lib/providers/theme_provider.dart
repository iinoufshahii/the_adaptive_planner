import 'package:flutter/material.dart';

/// Provider class managing application-wide theme state using Provider pattern.
///
/// Manages light/dark mode toggle and notifies listeners of theme changes for real-time UI updates.
///
/// Usage:
/// ```dart
/// final themeProvider = Provider.of<ThemeProvider>(context);
/// themeProvider.toggleTheme(true); // Switch to dark mode
/// bool isDark = themeProvider.isDarkMode;
/// ```
class ThemeProvider with ChangeNotifier {
  /// Internal state variable: stores current theme mode (light or dark)
  ThemeMode _themeMode = ThemeMode.light;

  /// Getter: returns current theme mode for consumption by widgets
  ThemeMode get themeMode => _themeMode;

  /// Getter: convenience method to check if currently in dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Method: toggles between light and dark themes and notifies all listening widgets.
  ///
  /// Parameters:
  /// - [isOn]: true switches to dark mode, false switches to light mode
  ///
  /// Effects:
  /// - Updates internal [_themeMode] state
  /// - Calls [notifyListeners()] to trigger rebuild of all widgets listening to this provider
  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
