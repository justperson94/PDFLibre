import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import 'toolbar_button.dart';
import 'view_toggle.dart';

/// Main screen top toolbar (48px height)
class TopToolbar extends StatelessWidget {
  const TopToolbar({
    super.key,
    required this.isGridView,
    required this.onViewChanged,
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
  });

  final bool isGridView;
  final ValueChanged<bool> onViewChanged;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      decoration: const BoxDecoration(
        color: AppTheme.toolbarBg,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left: app name + open file
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
          ToolbarButton(
            icon: LucideIcons.folderOpen,
            tooltip: '파일 열기',
            label: '파일 열기',
            iconColor: AppTheme.accentPrimary,
            onTap: onOpenFile,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.save,
            tooltip: '다른 이름으로 저장',
            onTap: onSave,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.x,
            tooltip: '문서 닫기',
            onTap: onClose,
          ),

          const Spacer(),

          // Center: Undo/Redo + tool buttons
          ToolbarButton(
            icon: LucideIcons.undo2,
            tooltip: '실행 취소 (Ctrl+Z)',
            onTap: canUndo ? onUndo : null,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.redo2,
            tooltip: '다시 실행 (Ctrl+Shift+Z)',
            onTap: canRedo ? onRedo : null,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingSm),
          ToolbarButton(
            icon: LucideIcons.rotateCcw,
            tooltip: '왼쪽으로 회전',
            onTap: onRotateCcw,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.rotateCw,
            tooltip: '오른쪽으로 회전',
            onTap: onRotateCw,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingSm),
          ToolbarButton(
            icon: LucideIcons.scissors,
            tooltip: '분할',
            onTap: onSplit,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(icon: LucideIcons.merge, tooltip: '병합', onTap: onMerge),
          const SizedBox(width: AppTheme.spacingXs),
          ToolbarButton(
            icon: LucideIcons.image,
            tooltip: '이미지로 변환',
            onTap: onConvert,
          ),

          const Spacer(),

          // Right: view toggle
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingMd),
          ViewToggle(isGrid: isGridView, onChanged: onViewChanged),
        ],
      ),
    );
  }
}
