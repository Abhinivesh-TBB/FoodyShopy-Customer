import '../network/network_service.dart';
import '../storage/secure_storage_service.dart';

class AppInitializer {
  AppInitializer._();

  static Future<bool> initialize() async {
    // Check internet
    await NetworkService.isConnected();

    // Read saved token
    final token = await SecureStorageService.getAccessToken();

    // Return true if user is logged in
    return token != null && token.isNotEmpty;
  }
}
