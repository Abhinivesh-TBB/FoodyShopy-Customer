import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message = 'Please wait...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        elevation: 6,
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator.adaptive(),

                const SizedBox(height: 20),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
