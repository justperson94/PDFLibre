import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_theme.dart';

class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitWidth,
    required this.onActualSize,
    required this.onFitHeight,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitWidth;
  final VoidCallback onActualSize;
  final VoidCallback onFitHeight;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      decoration: const BoxDecoration(
        color: AppTheme.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 페이지 네비게이션
          IconButton(
            onPressed: onPrev,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            color: AppTheme.foregroundSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '이전 페이지',
          ),
          Text(
            '페이지 $currentPage / $totalPages',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundPrimary,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(LucideIcons.chevronRight, size: 16),
            color: AppTheme.foregroundSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '다음 페이지',
          ),

          const Spacer(),

          // 줌 컨트롤
          IconButton(
            onPressed: onZoomOut,
            icon: const Icon(LucideIcons.minus, size: 14),
            color: AppTheme.foregroundSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: '축소',
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            '${zoom.round()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.foregroundSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(LucideIcons.plus, size: 14),
            color: AppTheme.foregroundSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: '확대',
          ),
          const SizedBox(width: AppTheme.spacingMd),

          // 가로 맞춤 / 원본 크기 / 세로 맞춤
          IconButton(
            onPressed: onFitWidth,
            icon: const Icon(LucideIcons.moveHorizontal, size: 16),
            color: AppTheme.accentPrimary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '가로 맞춤',
          ),
          IconButton(
            onPressed: onActualSize,
            icon: const Icon(LucideIcons.maximize, size: 16),
            color: AppTheme.accentPrimary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '원본 크기 (100%)',
          ),
          IconButton(
            onPressed: onFitHeight,
            icon: const Icon(LucideIcons.moveVertical, size: 16),
            color: AppTheme.accentPrimary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '세로 맞춤',
          ),
        ],
      ),
    );
  }
}
