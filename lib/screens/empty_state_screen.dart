import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../dialogs/error_dialog.dart';
import '../providers/pdf_provider.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/app_logo.dart';
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
          // Top toolbar (48px) — logo only, no duplicate open button
          _buildToolbar(),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Center content with drop zone
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PDF document icon
                  const Icon(
                    LucideIcons.fileText,
                    size: 56,
                    color: AppTheme.foregroundMuted,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Title
                  const Text(
                    'PDF 파일을 열어보세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  // Description
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

                  // CTA button
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
                        borderRadius:
                            BorderRadius.circular(AppTheme.roundedMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Feature highlights
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeatureChip(icon: LucideIcons.rotateCw, label: '회전'),
                      SizedBox(width: AppTheme.spacingSm),
                      _FeatureChip(icon: LucideIcons.scissors, label: '분할'),
                      SizedBox(width: AppTheme.spacingSm),
                      _FeatureChip(icon: LucideIcons.merge, label: '병합'),
                      SizedBox(width: AppTheme.spacingSm),
                      _FeatureChip(icon: LucideIcons.image, label: '변환'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Supported format hint
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

  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      color: AppTheme.toolbarBg,
      child: const Row(
        children: [
          AppLogo(),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.foregroundSecondary),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
