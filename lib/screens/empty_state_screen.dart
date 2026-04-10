import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../dialogs/error_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../l10n/strings.dart';
import '../providers/pdf_provider.dart';
import '../services/file_service.dart';
import '../services/recent_files_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/status_bar.dart';

/// Empty state screen — displayed on initial app launch
class EmptyStateScreen extends StatefulWidget {
  const EmptyStateScreen({super.key});

  @override
  State<EmptyStateScreen> createState() => _EmptyStateScreenState();
}

class _EmptyStateScreenState extends State<EmptyStateScreen> {
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final files = await RecentFilesService.load();
    if (mounted) setState(() => _recentFiles = files);
  }

  Future<void> _openFile() async {
    final s = S.of(context);
    final path = await FileService.pickPdfFile(dialogTitle: s.pickPdfFile);
    if (path == null || !mounted) return;
    _loadPdf(path);
  }

  Future<void> _loadPdf(String path, {bool fromRecent = false}) async {
    final s = S.of(context);
    final provider = context.read<PdfProvider>();
    final success = await provider.loadPdf(path);

    if (success) {
      await RecentFilesService.add(path);
      return;
    }

    // On failure, drop unreachable recents from the list and refresh UI.
    if (fromRecent) {
      await RecentFilesService.remove(path);
      if (mounted) await _loadRecentFiles();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fromRecent ? s.recentFileRemoved : s.cannotOpenFilePeriod,
        ),
      ),
    );
    showErrorDialog(context, onPickFile: _openFile);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: AppTheme.surfacePrimary,
      body: Column(
        children: [
          // Top toolbar (48px) — logo only
          _buildToolbar(s),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Center content with drop zone
          Expanded(
            child: Container(
              color: AppTheme.surfaceSecondary,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drop zone card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfacePrimary,
                            borderRadius: BorderRadius.circular(
                              AppTheme.roundedXl,
                            ),
                            border: Border.all(
                              color: AppTheme.borderSubtle,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.fileText,
                                size: 56,
                                color: AppTheme.foregroundMuted,
                              ),
                              const SizedBox(height: AppTheme.spacingXl),
                              Text(
                                s.openPdfPrompt,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.foregroundPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Text(
                                s.openPdfHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.foregroundSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXl),
                              FilledButton.icon(
                                onPressed: _openFile,
                                icon: const Icon(
                                  LucideIcons.folderOpen,
                                  size: 16,
                                ),
                                label: Text(
                                  s.openPdfButton,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.accentPrimary,
                                  foregroundColor: AppTheme.surfacePrimary,
                                  minimumSize: const Size(180, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.roundedMd,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              Wrap(
                                spacing: AppTheme.spacingSm,
                                runSpacing: AppTheme.spacingSm,
                                alignment: WrapAlignment.center,
                                children: [
                                  _FeatureChip(
                                    icon: LucideIcons.rotateCw,
                                    label: s.rotate,
                                  ),
                                  _FeatureChip(
                                    icon: LucideIcons.scissors,
                                    label: s.split,
                                  ),
                                  _FeatureChip(
                                    icon: LucideIcons.merge,
                                    label: s.merge,
                                  ),
                                  _FeatureChip(
                                    icon: LucideIcons.image,
                                    label: s.convert,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                s.multiFileMergeHint,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.foregroundMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Recent files section
                        if (_recentFiles.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingXl),
                          _buildRecentFiles(s),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom status bar (32px)
          StatusBar(
            leftText: s.selectFilePrompt,
            rightText: '${AppConstants.appName} ${AppConstants.appVersion}',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFiles(S s) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.recentFiles,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...List.generate(
            _recentFiles.length,
            (i) => _RecentFileItem(
              path: _recentFiles[i],
              onTap: () => _loadPdf(_recentFiles[i], fromRecent: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(S s) {
    final macOsLeftPad = Platform.isMacOS ? 54.0 : 0.0;
    return Container(
      height: 48,
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg + macOsLeftPad,
        right: AppTheme.spacingLg,
      ),
      color: AppTheme.toolbarBg,
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          IconButton(
            onPressed: () => showSettingsDialog(context),
            icon: const Icon(
              LucideIcons.settings,
              size: 18,
              color: AppTheme.foregroundSecondary,
            ),
            tooltip: s.settings,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _RecentFileItem extends StatelessWidget {
  const _RecentFileItem({required this.path, required this.onTap});

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fileName = Uri.file(path).pathSegments.last;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.roundedMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs + 2,
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.fileText,
              size: 14,
              color: AppTheme.foregroundMuted,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.foregroundSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
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
