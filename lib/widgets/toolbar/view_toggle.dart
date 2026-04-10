import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

class ViewToggle extends StatelessWidget {
  const ViewToggle({super.key, required this.isGrid, required this.onChanged});

  final bool isGrid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      children: [
        _ToggleIconButton(
          icon: LucideIcons.grid,
          tooltip: s.gridView,
          selected: isGrid,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: AppTheme.spacingXs),
        _ToggleIconButton(
          icon: LucideIcons.rows,
          tooltip: s.listView,
          selected: !isGrid,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ToggleIconButton extends StatelessWidget {
  const _ToggleIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? AppTheme.surfaceTertiary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.roundedMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Icon(
              icon,
              size: AppTheme.spacingMd + AppTheme.spacingXs,
              color: selected
                  ? AppTheme.accentPrimary
                  : AppTheme.foregroundSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
