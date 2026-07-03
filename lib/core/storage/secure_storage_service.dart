import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/constants.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.keyAccessToken);
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
  }
}
