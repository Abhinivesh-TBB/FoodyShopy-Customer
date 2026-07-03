import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/theme.dart';

class FoodyShopyApp extends ConsumerWidget {
  const FoodyShopyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'FoodyShopy',

      theme: AppTheme.light,

      routerConfig: router,
    );
  }
}
