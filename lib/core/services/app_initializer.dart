import '../network/network_service.dart';
import '../storage/local_cache.dart';
import '../storage/secure_storage_service.dart';
import 'push_notification_service.dart';

class AppInitializer {
  AppInitializer._();

  static Future<bool> initialize() async {
    try {
      // Initialize local cache
      await LocalCache.init();

      // Check internet connection
      final isConnected = await NetworkService.isConnected();

      // Initialize push notifications only if connected
      if (isConnected) {
        try {
          await PushNotificationService().initialize();
        } catch (_) {
          // TODO: Log notification initialization failure
        }
      }

      // Read saved authentication token
      final token = await SecureStorageService.getAccessToken();

      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
