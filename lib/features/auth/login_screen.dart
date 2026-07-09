import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_text_styles.dart';
import '../../app/router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/utils/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    // 1. Dismiss the keyboard immediately when the button is pressed
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Optional: Prevent multiple submissions if already loading
    if (ref.read(authProvider).isLoading) return;

    final phoneNumber = _phoneController.text.trim();

    final success = await ref.read(authProvider.notifier).sendOtp(phoneNumber);

    // 2. Safety check before navigating
    if (!mounted) return;

    if (success) {
      // 3. Direct navigation (no post-frame callback needed)
      // Passing the phone number as extra data to the OTP screen
      context.push(AppRoutes.otp, extra: phoneNumber);
    } else {
      AppSnackbar.showError(context, "Failed to send OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(),

                  const SizedBox(height: 50),

                  Text(
                    "Welcome Back 👋",
                    style: AppTextStyles.heading1,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Sign in to continue ordering delicious food.",
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  CustomTextField(
                    controller: _phoneController,
                    labelText: "Mobile Number",
                    hintText: "Enter your mobile number",
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textInputAction: TextInputAction.done,
                    prefix: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text("+91", style: TextStyle(fontSize: 16)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your mobile number";
                      }
                      if (value.length != 10) {
                        return "Enter a valid 10-digit number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "We'll send you a One-Time Password (OTP).",
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(height: 35),

                  PrimaryButton(
                    text: "Continue",
                    isLoading: authState.isLoading,
                    onPressed: _continue,
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "By continuing you agree to our Terms & Conditions and Privacy Policy.",
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
