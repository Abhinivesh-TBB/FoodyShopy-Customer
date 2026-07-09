import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../services/logger_service.dart';

class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Request notification permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      LoggerService.logger.i(
        'Notification permission: ${settings.authorizationStatus}',
      );

      // Register current FCM token
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        LoggerService.logger.i('FCM Token: $token');
        await registerFcmToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        LoggerService.logger.i('FCM token refreshed.');
        await registerFcmToken(newToken);
      });

      // Foreground notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        LoggerService.logger.i(
          'Foreground notification: ${message.notification?.title}',
        );
      });

      _initialized = true;
    } catch (e, stackTrace) {
      LoggerService.logger.e(
        'Failed to initialize push notifications.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> registerFcmToken(String token) async {
    try {
      final response = await ApiClient.dio.put(
        '/customer/profile',
        data: {'fcm_token': token},
      );

      if (response.statusCode == 200) {
        LoggerService.logger.i('FCM token registered successfully.');
      }
    } catch (e, stackTrace) {
      LoggerService.logger.e(
        'Failed to register FCM token.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
