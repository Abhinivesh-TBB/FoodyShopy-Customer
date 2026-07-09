import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/constants.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // =========================
  // Access Token
  // =========================

  static Future<void> saveAccessToken(String token) {
    return _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  static Future<String?> getAccessToken() {
    return _storage.read(key: AppConstants.keyAccessToken);
  }

  static Future<void> deleteAccessToken() {
    return _storage.delete(key: AppConstants.keyAccessToken);
  }

  // =========================
  // Refresh Token
  // =========================

  static Future<void> saveRefreshToken(String token) {
    return _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() {
    return _storage.read(key: AppConstants.keyRefreshToken);
  }

  static Future<void> deleteRefreshToken() {
    return _storage.delete(key: AppConstants.keyRefreshToken);
  }

  // =========================
  // Authentication
  // =========================

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.keyAccessToken),
      _storage.delete(key: AppConstants.keyRefreshToken),
    ]);
  }

  static Future<void> clearAll() {
    return _storage.deleteAll();
  }
}
