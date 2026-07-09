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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _backgroundColor;
  late Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Setup the animation controller (Snappier duration: 1.2 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 2. Animate background: Red -> White (happens during the first 60% of the animation)
    _backgroundColor =
        ColorTween(
          begin: const Color.fromRGBO(253, 81, 61, 1.0),
          end: Colors.white,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
          ),
        );

    // 3. Fade in logo: Invisible -> Visible
    // (Starts at 0.4 to overlap nicely as the background turns white)
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // 4. Start the animation, then initialize the app
    _controller.forward().then((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Check app state
    final isLoggedIn = await AppInitializer.initialize();

    if (!mounted) return;

    if (isLoggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          // Background color updates smoothly from red to white
          backgroundColor: _backgroundColor.value,
          body: Center(
            child: Opacity(
              // Logo opacity updates from 0.0 to 1.0
              opacity: _contentOpacity.value,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(
                    showTitle: false,
                    // logoColor: Color.fromRGBO(
                    //   253,
                    //   81,
                    //   61,
                    //   1.0,
                    // ), // Set logo to Red
                    size: 120,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'FoodyShopy',
                    style: TextStyle(
                      color: Color.fromRGBO(
                        253,
                        81,
                        61,
                        1.0,
                      ), // Set text to Red
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
