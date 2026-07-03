import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  int _seconds = 30;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  void _verifyOtp() {
    final otp = _controllers.map((e) => e.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the complete OTP')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final c in _controllers) {
      c.dispose();
    }

    for (final f in _focusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,

        decoration: const InputDecoration(counterText: ""),

        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }

          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const AppLogo(),

              const SizedBox(height: 40),

              Text("Verify Your Number", style: AppTextStyles.heading1),

              const SizedBox(height: 10),

              Text(
                "We've sent a 6-digit verification code",
                style: AppTextStyles.caption,
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, otpBox),
              ),

              const SizedBox(height: 30),

              Text(
                "00:${_seconds.toString().padLeft(2, '0')}",
                style: AppTextStyles.heading2,
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: _seconds == 0
                    ? () {
                        _startTimer();
                      }
                    : null,
                child: const Text("Resend OTP"),
              ),

              const SizedBox(height: 30),

              PrimaryButton(
                text: "Verify & Continue",
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text("Change Number"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
