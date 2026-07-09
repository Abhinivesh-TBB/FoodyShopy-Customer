import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  LocalCache._();

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences.
  /// Call this once during app startup.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception(
        'LocalCache has not been initialized. Call LocalCache.init() first.',
      );
    }
    return _prefs!;
  }

  // =========================
  // String
  // =========================

  static Future<bool> setString(String key, String value) {
    return _instance.setString(key, value);
  }

  static String? getString(String key) {
    return _instance.getString(key);
  }

  // =========================
  // Bool
  // =========================

  static Future<bool> setBool(String key, bool value) {
    return _instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  // =========================
  // Int
  // =========================

  static Future<bool> setInt(String key, int value) {
    return _instance.setInt(key, value);
  }

  static int? getInt(String key) {
    return _instance.getInt(key);
  }

  // =========================
  // Double
  // =========================

  static Future<bool> setDouble(String key, double value) {
    return _instance.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _instance.getDouble(key);
  }

  // =========================
  // String List
  // =========================

  static Future<bool> setStringList(String key, List<String> value) {
    return _instance.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _instance.getStringList(key);
  }

  // =========================
  // Generic
  // =========================

  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  static Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  static Future<bool> clear() {
    return _instance.clear();
  }
}
