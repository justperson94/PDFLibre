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

/// Empty state screen — displayed on initial app launch.
///
/// When [isDragging] is true, the central drop zone card transforms to
/// signal that a drop is in progress (accent border + tint, icon/text
/// swapped to drag prompt). The button and shortcuts stay in place to
/// avoid layout shift while the pointer is over the window.
class EmptyStateScreen extends StatefulWidget {
  const EmptyStateScreen({super.key, this.isDragging = false});

  final bool isDragging;

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
    final colors = context.colors;
    final dragging = widget.isDragging;
    final dropZoneBg = dragging
        ? Color.alphaBlend(
            colors.accentPrimary.withValues(alpha: 0.08),
            colors.surfacePrimary,
          )
        : colors.surfacePrimary;
    final dropZoneBorderColor =
        dragging ? colors.accentPrimary : colors.borderSubtle;
    // NOTE: keep width constant. Border.all defaults to strokeAlignInside, so
    // changing width shifts the container size and visibly jitters the card.
    const dropZoneBorderWidth = 1.5;
    final headingText = dragging ? s.dropHere : s.openPdfPrompt;
    final hintText = dragging ? s.dropDescription : s.openPdfHint;
    final headingColor =
        dragging ? colors.accentPrimary : colors.foregroundPrimary;
    final iconData = dragging ? LucideIcons.download : LucideIcons.fileText;
    final iconColor =
        dragging ? colors.accentPrimary : colors.foregroundMuted;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      body: Column(
        children: [
          // Top toolbar (48px) — logo only
          _buildToolbar(s),
          Divider(height: 1, color: colors.borderSubtle),

          // Center content with drop zone
          Expanded(
            child: Container(
              color: colors.surfaceSecondary,
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drop zone card — fixed width so text swaps
                        // don't resize the card during drag transition.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 440,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            color: dropZoneBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.roundedXl,
                            ),
                            border: Border.all(
                              color: dropZoneBorderColor,
                              width: dropZoneBorderWidth,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconData,
                                size: 56,
                                color: iconColor,
                              ),
                              const SizedBox(height: AppTheme.spacingXl),
                              Text(
                                headingText,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: headingColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              SizedBox(
                                height: 42, // 2 lines (fontSize 14 × 1.5 × 2)
                                child: Text(
                                  hintText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.foregroundSecondary,
                                    height: 1.5,
                                  ),
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
                                  backgroundColor: context.colors.accentPrimary,
                                  foregroundColor: context.colors.surfacePrimary,
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.foregroundMuted,
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
        color: context.colors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        border: Border.all(color: context.colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.recentFiles,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.foregroundPrimary,
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      color: context.colors.toolbarBg,
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          IconButton(
            onPressed: () => showSettingsDialog(context),
            icon: Icon(
              LucideIcons.settings,
              size: 18,
              color: context.colors.foregroundSecondary,
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
            Icon(
              LucideIcons.fileText,
              size: 14,
              color: context.colors.foregroundMuted,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.foregroundSecondary,
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
          Icon(icon, size: 14, color: context.colors.foregroundSecondary),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
