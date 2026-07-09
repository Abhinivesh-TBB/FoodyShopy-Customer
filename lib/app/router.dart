// Flutter
import 'package:flutter/material.dart';

// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core
import '../core/storage/secure_storage_service.dart';
import 'theme/theme.dart';

// Features
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/presentation/views/account_view.dart';
import '../features/home/presentation/views/history_view.dart';
import '../features/location/screens/location_permission_screen.dart';
import '../features/location/screens/map_picker_screen.dart';
import '../features/location/screens/select_address_screen.dart';
import '../features/orders/presentation/order_tracking_screen.dart';
import '../features/restaurant/presentation/restaurant_detail_screen.dart';
import '../features/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  // =========================
  // Authentication
  // =========================
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';

  // Route Names
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String otpName = 'otp';

  // =========================
  // Customer
  // =========================
  static const String home = '/home';
  static const String menu = '/menu/:restaurantId';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String tracking = '/tracking/:orderId';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String selectAddress = '/select-address';
  static const String mapPicker = '/map-picker';
  static const String locationPermission = '/location-permission';

  // Route Names
  static const String homeName = 'home';
  static const String menuName = 'menu';
  static const String cartName = 'cart';
  static const String checkoutName = 'checkout';
  static const String trackingName = 'tracking';
  static const String historyName = 'history';
  static const String profileName = 'profile';
  static const String selectAddressName = 'selectAddress';
  static const String mapPickerName = 'mapPicker';
  static const String locationPermissionName = 'locationPermission';

  // =========================
  // Dynamic Paths
  // =========================
  static String menuPath(String restaurantId) => '/menu/$restaurantId';

  static String trackingPath(String orderId) => '/tracking/$orderId';
}

///
/// Router Provider
///
/// Keeping the router inside Riverpod allows us to
/// easily add authentication redirects later without
/// changing the architecture.
class RouterListenable extends ChangeNotifier {
  final Ref _ref;

  RouterListenable(this._ref) {
    _ref.listen(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

///
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RouterListenable(ref);

  // Dispose the ChangeNotifier when the provider is destroyed.
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,

    redirect: (context, state) async {
      final token = await SecureStorageService.getAccessToken();
      final isLoggedIn = token != null && token.isNotEmpty;

      final isLoggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.otp;

      if (!isLoggedIn) {
        if (!isLoggingIn && state.matchedLocation != AppRoutes.splash) {
          return AppRoutes.login;
        }
      } else {
        if (isLoggingIn) {
          return AppRoutes.home;
        }
      }
      return null;
    },

    routes: [
      // Splash
      GoRoute(
        name: AppRoutes.splashName,
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: child,
          );
        },
        routes: [
          // Login
          GoRoute(
            name: AppRoutes.loginName,
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),

          // OTP
          GoRoute(
            name: AppRoutes.otpName,
            path: AppRoutes.otp,
            builder: (context, state) => const OtpScreen(),
          ),

          // Home
          GoRoute(
            name: AppRoutes.homeName,
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),

          // Restaurant Menu
          GoRoute(
            name: AppRoutes.menuName,
            path: AppRoutes.menu,
            builder: (context, state) {
              final restaurantId = state.pathParameters['restaurantId']!;
              return RestaurantDetailScreen(restaurantId: restaurantId);
            },
          ),

          // Cart
          GoRoute(
            name: AppRoutes.cartName,
            path: AppRoutes.cart,
            builder: (context, state) => const CartScreen(),
          ),

          // Location Permission
          GoRoute(
            name: AppRoutes.locationPermissionName,
            path: AppRoutes.locationPermission,
            builder: (context, state) => const LocationPermissionScreen(),
          ),

          // Select Address
          GoRoute(
            name: AppRoutes.selectAddressName,
            path: AppRoutes.selectAddress,
            builder: (context, state) => const SelectAddressScreen(),
          ),

          // Map Picker
          GoRoute(
            name: AppRoutes.mapPickerName,
            path: AppRoutes.mapPicker,
            builder: (context, state) => const MapPickerScreen(),
          ),

          // Checkout
          GoRoute(
            name: AppRoutes.checkoutName,
            path: AppRoutes.checkout,
            builder: (context, state) => const CheckoutScreen(),
          ),

          // Tracking
          GoRoute(
            name: AppRoutes.trackingName,
            path: AppRoutes.tracking,
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderTrackingScreen(orderId: orderId);
            },
          ),

          // Order History
          GoRoute(
            name: AppRoutes.historyName,
            path: AppRoutes.history,
            builder: (context, state) => const HistoryView(),
          ),

          // Profile
          GoRoute(
            name: AppRoutes.profileName,
            path: AppRoutes.profile,
            builder: (context, state) => const Scaffold(body: AccountView()),
          ),
        ],
      ),
    ],

    // Unknown Route
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text(
            'No route defined for:\n${state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
});

