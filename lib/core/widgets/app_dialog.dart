import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';

class AppDialog {
  AppDialog._();

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool barrierDismissible = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title, style: AppTextStyles.heading2),
          content: Text(message, style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(false);
                }
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(true);
                }
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
