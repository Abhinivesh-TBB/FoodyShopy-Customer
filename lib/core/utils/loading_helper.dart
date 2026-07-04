import 'package:flutter/material.dart';

import '../widgets/loading_overlay.dart';

class LoadingHelper {
  LoadingHelper._();

  static void show(BuildContext context, {String message = 'Please wait...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingOverlay(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
