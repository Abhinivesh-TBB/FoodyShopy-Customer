import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';

class FoodyShopyApp extends StatelessWidget {
  const FoodyShopyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodyShopy',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
