import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Branded app logo: icon + "PDF"(blue) + "Libre"(coral)
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.iconSize = 24,
    this.fontSize = 18,
    this.showIcon = true,
  });

  final double iconSize;
  final double fontSize;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Image.asset(
            'assets/app_icon.png',
            width: iconSize,
            height: iconSize,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) =>
                SizedBox(width: iconSize, height: iconSize),
          ),
          const SizedBox(width: AppTheme.spacingSm),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'PDF',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: colors.brandBlue,
                ),
              ),
              TextSpan(
                text: 'Libre',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: colors.accentPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
