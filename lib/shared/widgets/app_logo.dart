import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';
import '../../app/theme/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showTitle;
  final Color? logoColor;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showTitle = true,
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/foodyshopy_logo.png',
          width: size,
          height: size,
          color: logoColor,
        ),

        if (showTitle) ...[
          const SizedBox(height: 16),

          Text(
            'FoodyShopy',
            style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
