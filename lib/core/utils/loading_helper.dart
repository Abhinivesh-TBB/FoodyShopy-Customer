import 'package:flutter/material.dart';

import '../widgets/loading_overlay.dart';

class LoadingHelper {
  LoadingHelper._();

  static bool _isShowing = false;

  static Future<void> show(
    BuildContext context, {
    String message = 'Please wait...',
  }) async {
    if (_isShowing || !context.mounted) return;

    _isShowing = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => LoadingOverlay(message: message),
    );

    _isShowing = false;
  }

  static void hide(BuildContext context) {
    if (!_isShowing || !context.mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
  }
}
