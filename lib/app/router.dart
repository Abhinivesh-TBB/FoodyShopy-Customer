import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const menu = '/menu/:restaurantId';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const tracking = '/tracking/:orderId';
  static const history = '/history';
  static const profile = '/profile';

  static String menuPath(String restaurantId) => '/menu/$restaurantId';
  static String trackingPath(String orderId) => '/tracking/$orderId';
}

/// Exposed as a provider (not a plain top-level GoRouter) so Phase 4 can add
/// `redirect:` driven by an authState provider without restructuring this file.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const _Placeholder('Login'),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const _Placeholder('OTP Verify'),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _Placeholder('Home'),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (context, state) =>
            _Placeholder('Menu — ${state.pathParameters['restaurantId']}'),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const _Placeholder('Cart'),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const _Placeholder('Checkout'),
      ),
      GoRoute(
        path: AppRoutes.tracking,
        builder: (context, state) =>
            _Placeholder('Tracking — ${state.pathParameters['orderId']}'),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const _Placeholder('Order History'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const _Placeholder('Profile'),
      ),
    ],
  );
});

/// Temporary stand-in until each real screen is built in later phases.
class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen — coming soon')),
    );
  }
}
