import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onFitWidth,
    required this.onActualSize,
    required this.onFitHeight,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onFitWidth;
  final VoidCallback onActualSize;
  final VoidCallback onFitHeight;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
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
          // Page navigation
          IconButton(
            onPressed: onPrev,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            color: AppTheme.foregroundSecondary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: s.prevPage,
          ),
          Text(
            s.pageOf(currentPage, totalPages),
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
            tooltip: s.nextPage,
          ),

          const Spacer(),

          // Fit width / Actual size / Fit height
          IconButton(
            onPressed: onFitWidth,
            icon: const Icon(LucideIcons.moveHorizontal, size: 16),
            color: AppTheme.accentPrimary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: s.fitWidth,
          ),
          IconButton(
            onPressed: onActualSize,
            icon: const Icon(LucideIcons.maximize, size: 16),
            color: AppTheme.accentPrimary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: s.actualSize,
          ),
          IconButton(
            onPressed: onFitHeight,
            icon: const Icon(LucideIcons.moveVertical, size: 16),
            color: AppTheme.accentPrimary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: s.fitHeight,
          ),
        ],
      ),
    );
  }
}
