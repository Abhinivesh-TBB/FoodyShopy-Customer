import 'dart:async';
import 'package:flutter/material.dart';

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
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showWhite = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
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
                Image.asset(
                  'assets/images/quiz_logo.png',
                  color: Colors.black,
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'FoodyShopy',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 94, 1),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
