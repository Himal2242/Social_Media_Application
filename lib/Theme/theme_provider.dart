import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'light_mode.dart';
import 'dark_mode.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;
  bool? _userPrefersDark; // null = no preference saved yet

  ThemeProvider()
      : _themeData = WidgetsBinding.instance.window.platformBrightness == Brightness.dark
            ? darkMode
            : lightMode {
    _loadThemeFromPrefs();
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData.brightness == Brightness.dark;

  // Toggle and save user preference
  Future<void> toggleTheme() async {
    _userPrefersDark = !isDarkMode;
    _themeData = _userPrefersDark! ? darkMode : lightMode;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  // Load saved preference, or default to system theme
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPref = prefs.getBool('isDarkMode');

    if (savedPref != null) {
      _userPrefersDark = savedPref;
      _themeData = _userPrefersDark! ? darkMode : lightMode;
      notifyListeners();
    }
    // else → use system theme (already initialized in constructor)
  }

  // Save user's manual theme choice
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _userPrefersDark ?? isDarkMode);
  }
}


// import 'package:flutter/material.dart';
// import 'light_mode.dart';
// import 'dark_mode.dart';

// class ThemeProvider with ChangeNotifier {
//   ThemeData _themeData;

//   ThemeProvider()
//       : _themeData = WidgetsBinding.instance.window.platformBrightness == Brightness.dark
//             ? darkMode
//             : lightMode;

//   ThemeData get themeData => _themeData;

//   bool get isDarkMode => _themeData.brightness == Brightness.dark;

//   void toggleTheme() {
//     _themeData = isDarkMode ? lightMode : darkMode;
//     notifyListeners();
//   }
// }



