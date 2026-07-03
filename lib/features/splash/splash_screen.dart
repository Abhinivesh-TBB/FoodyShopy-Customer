import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../core/services/app_initializer.dart';
import '../../app/router.dart';
import '../../shared/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showWhite = false;

  @override
  void initState() {
    super.initState();

    Timer(AppConstants.splashDuration, () {
      if (mounted) {
        setState(() => _showWhite = true);

        // Wait for the fade animation
        Timer(AppConstants.splashFadeDuration, () async {
          if (!mounted) return;

          // Check app state
          final isLoggedIn = await AppInitializer.initialize();

          if (!mounted) return;

          if (isLoggedIn) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.login);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: AppConstants.splashFadeDuration,
        curve: Curves.easeInOut,
        color: _showWhite ? Colors.white : Colors.orange,
        width: double.infinity,
        height: double.infinity,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: _showWhite ? 1.0 : 0.0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(logoColor: Colors.black),
                const SizedBox(height: 16),
                // const Text(
                //   'FoodyShopy',
                //   style: TextStyle(
                //     color: Color.fromARGB(255, 255, 94, 1),
                //     fontSize: 26,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
