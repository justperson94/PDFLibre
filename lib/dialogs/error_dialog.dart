import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

Future<void> showErrorDialog(BuildContext context, {VoidCallback? onPickFile}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final s = context.s;
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.roundedXl),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                  vertical: AppTheme.spacingXl + AppTheme.spacingSm,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        color: AppTheme.accentPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      s.errorDialogTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foregroundPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      s.errorDialogBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.foregroundSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPickFile?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(110, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.roundedMd,
                          ),
                        ),
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        foregroundColor: AppTheme.foregroundSecondary,
                      ),
                      child: Text(s.pickAnotherFile),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        foregroundColor: AppTheme.surfacePrimary,
                        minimumSize: const Size(80, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.roundedMd,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        s.confirm,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
