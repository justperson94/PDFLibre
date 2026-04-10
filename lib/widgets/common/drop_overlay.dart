import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

class DropOverlay extends StatelessWidget {
  const DropOverlay({super.key});

  static const _overlayBg = Color(0xFFFFF5F3);
  static const _iconBg = Color(0xFFFCE8E5);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingXl * 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl * 3,
          vertical: AppTheme.spacingXl * 3,
        ),
        decoration: BoxDecoration(
          color: _overlayBg,
          borderRadius: BorderRadius.circular(AppTheme.roundedXl),
          border: Border.all(color: AppTheme.accentPrimary, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.download,
                size: 32,
                color: AppTheme.accentPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              s.dropHere,
              style: const TextStyle(
                color: AppTheme.foregroundPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              s.dropDescription,
              style: const TextStyle(
                color: AppTheme.foregroundSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.fileText,
                  size: 16,
                  color: AppTheme.foregroundMuted,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  s.supportedFormat,
                  style: const TextStyle(
                    color: AppTheme.foregroundMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
