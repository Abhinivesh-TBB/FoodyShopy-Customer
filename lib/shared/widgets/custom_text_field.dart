import 'package:flutter/material.dart';
//import '../../app/theme/theme.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;

  final TextInputType keyboardType;

  final bool obscureText;
  final bool enabled;
  final bool readOnly;

  final Widget? prefix;
  final Widget? suffix;

  final String? Function(String?)? validator;

  final void Function(String)? onChanged;

  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,

      style: AppTextStyles.body,

      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,

        prefixIcon: prefix,
        suffixIcon: suffix,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
