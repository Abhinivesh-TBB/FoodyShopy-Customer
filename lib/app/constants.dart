class AppConstants {
  AppConstants._();

  // =========================
  // App
  // =========================
  static const String appName = 'FoodyShopy';

  // =========================
  // API
  // =========================
  static const String apiBaseUrl = 'https://api.yourapp.com';
  static const String wsBaseUrl = 'wss://ws.yourapp.com';
  static const String customerApiPrefix = '/customer';

  // =========================
  // Network Timeouts
  // =========================
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // =========================
  // Secure Storage Keys
  // =========================
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  // =========================
  // Local Storage Keys
  // =========================
  static const String keyCart = 'cart_items';

  // =========================
  // Splash Screen
  // =========================
  static const Duration splashDuration = Duration(milliseconds: 1500);

  static const Duration splashFadeDuration = Duration(milliseconds: 600);
}
