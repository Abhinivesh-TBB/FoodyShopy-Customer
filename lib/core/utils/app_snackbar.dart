import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

class AppSnackbar {
  AppSnackbar._();

  static const Duration _defaultDuration = Duration(seconds: 3);

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message,
      AppColors.success,
      Icons.check_circle_rounded,
      duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, AppColors.error, Icons.error_rounded, duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message,
      AppColors.warning,
      Icons.warning_amber_rounded,
      duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, AppColors.info, Icons.info_rounded, duration);
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
    Duration? duration,
  ) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration ?? _defaultDuration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
