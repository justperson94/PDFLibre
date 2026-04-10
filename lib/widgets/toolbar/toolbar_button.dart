import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ToolbarButton extends StatefulWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.label,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final String? label;

  /// Icon colour override. Falls back to `context.colors.foregroundSecondary`.
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onTap != null;
    final resolvedIconColor = widget.iconColor ?? colors.foregroundSecondary;
    final color = enabled
        ? resolvedIconColor
        : colors.foregroundMuted.withValues(alpha: 0.65);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: Material(
          color: _hovered && enabled
              ? colors.surfaceTertiary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.roundedMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: AppTheme.spacingMd + AppTheme.spacingXs,
                    color: color,
                  ),
                  if (widget.label != null) ...[
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      widget.label!,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
