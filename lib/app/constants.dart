class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'https://api.yourapp.com';
  static const String wsBaseUrl = 'wss://ws.yourapp.com';
  static const String customerApiPrefix = '/customer';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Secure storage keys (tokens only — never non-sensitive data here)
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  // Local (non-sensitive) storage keys
  static const String keyCart = 'cart_items';

  // Splash timings
  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration splashFadeDuration = Duration(milliseconds: 600);
}
