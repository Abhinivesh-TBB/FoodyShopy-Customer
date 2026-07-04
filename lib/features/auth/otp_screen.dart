import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/router.dart';

import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/primary_button.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

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

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((e) => e.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete OTP")),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyOtp(otp);

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
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
    final authState = ref.watch(authProvider);
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
              Text("+91 ${authState.phoneNumber}", style: AppTextStyles.body),
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
                isLoading: authState.isLoading,
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
