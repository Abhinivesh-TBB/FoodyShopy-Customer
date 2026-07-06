import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  LocalCache._();

  static late final SharedPreferences _prefs;

  /// Call this in your app initializer before using any methods
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }

  static Future<bool> clear() async {
    return _prefs.clear();
  }
}
