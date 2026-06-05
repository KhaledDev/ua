import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _ramadanModeKey = 'ramadan_mode';

  static Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeKey) ?? 2; // Default to system
  }

  static Future<void> setThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode);
  }

  static Future<bool> isRamadanMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ramadanModeKey) ?? false;
  }

  static Future<void> setRamadanMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ramadanModeKey, enabled);
  }
}
