class AppConstants {
  AppConstants._();

  // =========================
  // Application
  // =========================
  static const String appName = 'FoodyShopy';

  // =========================
  // API Configuration
  // =========================
  static const String apiBaseUrl = 'https://api.yourapp.com';
  static const String wsBaseUrl = 'wss://ws.yourapp.com';

  static const String apiVersion = '/v1';
  static const String customerApiPrefix = '/customer';

  static const bool useMockApi = true;

  // =========================
  // Network
  // =========================
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  static const String refreshEndpoint = '/auth/refresh';

  // =========================
  // Secure Storage Keys
  // =========================
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  // =========================
  // Local Storage Keys
  // =========================
  static const String keyCartItems = 'cart_items';
  static const String keyUser = 'user';
  static const String keyAddresses = 'addresses';
  static const String keyIsLoggedIn = 'is_logged_in';

  // =========================
  // Splash Screen
  // =========================
  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration splashFadeDuration = Duration(milliseconds: 600);
}
