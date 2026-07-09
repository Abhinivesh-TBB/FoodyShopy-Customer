import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/router.dart';
import '../../core/services/app_initializer.dart';
import '../../shared/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(AppConstants.splashDuration, () async {
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromRGBO(253, 81, 61, 1.0),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // children: [
          //   AppLogo(showTitle: false, logoColor: Colors.white, size: 120),
          //   SizedBox(height: 16),
          //   Text(
          //     'FoodyShopy',
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 28,
          //       fontWeight: FontWeight.bold,
          //       letterSpacing: 1.2,
          //     ),
          //   ),
          // ],
        ),
      ),
    );
  }
}
