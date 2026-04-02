import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../dialogs/error_dialog.dart';
import '../providers/pdf_provider.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/status_bar.dart';

/// Empty state screen — displayed on initial app launch
class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({super.key});

  Future<void> _openFile(BuildContext context) async {
    final path = await FileService.pickPdfFile();
    if (path == null || !context.mounted) return;

    final provider = context.read<PdfProvider>();
    final success = await provider.loadPdf(path);

    if (!success && context.mounted) {
      showErrorDialog(context, onPickFile: () => _openFile(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfacePrimary,
      body: Column(
        children: [
          // Top toolbar (48px)
          _buildToolbar(context),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Center content
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    size: 48,
                    color: AppTheme.foregroundMuted,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  const Text(
                    'PDF 파일을 열어보세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  const Text(
                    '파일을 드래그하여 놓거나, 아래 버튼으로 열 수 있습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.foregroundSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  FilledButton.icon(
                    onPressed: () => _openFile(context),
                    icon: const Icon(LucideIcons.folderOpen, size: 16),
                    label: const Text(
                      'PDF 파일 열기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      foregroundColor: AppTheme.surfacePrimary,
                      minimumSize: const Size(160, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const Text(
                    '지원 형식: .pdf',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom status bar (32px)
          const StatusBar(
            leftText: '준비됨',
            rightText: '${AppConstants.appName} ${AppConstants.appVersion}',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      color: AppTheme.toolbarBg,
      child: Row(
        children: [
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingMd),
          TextButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(LucideIcons.folderOpen, size: 16),
            label: const Text(
              '파일 열기',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
