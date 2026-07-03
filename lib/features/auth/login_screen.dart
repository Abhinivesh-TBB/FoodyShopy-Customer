import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/../app/theme/app_text_styles.dart';
import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      context.go(AppRoutes.otp);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    isLoading: _isLoading,
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
