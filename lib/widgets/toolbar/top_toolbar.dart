import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../common/app_logo.dart';
import 'toolbar_button.dart';

String _shortcutPrefix() => Platform.isMacOS ? 'Cmd' : 'Ctrl';

/// Main screen top toolbar (48px height)
class TopToolbar extends StatelessWidget {
  const TopToolbar({
    super.key,
    this.onOpenFile,
    this.onClose,
    this.onSave,
    this.onRotateCcw,
    this.onRotateCw,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.onSplit,
    this.onMerge,
    this.onConvert,
    this.onSettings,
  });

  final VoidCallback? onOpenFile;
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final VoidCallback? onRotateCcw;
  final VoidCallback? onRotateCw;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onSplit;
  final VoidCallback? onMerge;
  final VoidCallback? onConvert;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final macOsLeftPad = Platform.isMacOS ? 54.0 : 0.0;
    return Container(
      height: 48,
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg + macOsLeftPad,
        right: AppTheme.spacingLg,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.toolbarBg,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left: branded logo + open file
          const AppLogo(),
          const SizedBox(width: AppTheme.spacingMd),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingMd),
          ToolbarButton(
            icon: LucideIcons.folderOpen,
            tooltip: s.openFileTooltip(_shortcutPrefix()),
            label: s.openLabel,
            iconColor: AppTheme.accentPrimary,
            onTap: onOpenFile,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.save,
            tooltip: s.saveAsTooltip,
            onTap: onSave,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.x,
            tooltip: s.closeDocTooltip,
            onTap: onClose,
          ),

          const Spacer(),

          // Center: Undo/Redo + tool buttons
          ToolbarButton(
            icon: LucideIcons.undo2,
            tooltip: s.undoTooltip(_shortcutPrefix()),
            onTap: canUndo ? onUndo : null,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.redo2,
            tooltip: s.redoTooltip(_shortcutPrefix()),
            onTap: canRedo ? onRedo : null,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingSm),
          ToolbarButton(
            icon: LucideIcons.rotateCcw,
            tooltip: s.rotateLeft,
            onTap: onRotateCcw,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.rotateCw,
            tooltip: s.rotateRight,
            onTap: onRotateCw,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingSm),
          ToolbarButton(
            icon: LucideIcons.scissors,
            tooltip: s.splitLabel,
            label: s.splitLabel,
            onTap: onSplit,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.merge,
            tooltip: s.mergeLabel,
            label: s.mergeLabel,
            onTap: onMerge,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.image,
            tooltip: s.convertToImage,
            label: s.convertLabel,
            onTap: onConvert,
          ),

          const Spacer(),

          // Right: Settings gear
          ToolbarButton(
            icon: LucideIcons.settings,
            tooltip: s.settingsTooltip(_shortcutPrefix()),
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}
