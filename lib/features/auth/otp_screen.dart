import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/router.dart';
import '../../core/utils/app_snackbar.dart';
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
    _setupFocusNodes();
    _startTimer();
  }

  void _setupFocusNodes() {
    for (int i = 0; i < 6; i++) {
      _focusNodes[i] = FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[i].text.isEmpty && i > 0) {
              _focusNodes[i - 1].requestFocus();
              _controllers[i - 1].clear();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
      );
    }
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
      AppSnackbar.showInfo(context, "Please enter the complete OTP");
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyOtp(otp);

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      AppSnackbar.showError(context, "Invalid OTP");
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
      width: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          counterText: "",
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 6) {
            for (int i = 0; i < 6; i++) {
              _controllers[i].text = value[i];
            }
            _focusNodes[5].requestFocus();
            _verifyOtp();
            return;
          }

          if (value.length > 1) {
            _controllers[index].text = value.characters.last;
            _controllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[index].text.length),
            );
          }

          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
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
                    ? () async {
                        final phone = ref.read(authProvider).phoneNumber;
                        final success = await ref
                            .read(authProvider.notifier)
                            .sendOtp(phone);
                        if (success && mounted) {
                          _startTimer();
                          AppSnackbar.showSuccess(
                            context,
                            "OTP resent successfully to +91 $phone",
                          );
                        } else if (mounted) {
                          AppSnackbar.showError(
                            context,
                            "Failed to resend OTP",
                          );
                        }
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
