import '../network/network_service.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_cache.dart';
import 'push_notification_service.dart';

class AppInitializer {
  AppInitializer._();

  static Future<bool> initialize() async {
    // Initialize Local Cache (SharedPreferences)
    await LocalCache.init();

    // Check internet
    await NetworkService.isConnected();

    // Initialize Push Notifications (Firebase Messaging)
    await PushNotificationService().initialize();

    // Read saved token
    final token = await SecureStorageService.getAccessToken();

    // Return true if user is logged in
    return token != null && token.isNotEmpty;
  }
}

