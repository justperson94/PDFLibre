import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

Future<void> showErrorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
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
                    const Text(
                      '파일을 열 수 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foregroundPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'PDF 파일이 손상되었거나 지원하지 않는 형식입니다.\n다른 파일을 선택해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                      onPressed: () => Navigator.of(context).pop(),
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
                      child: const Text('다른 파일 선택'),
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
                      child: const Text(
                        '확인',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
