import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ToolbarButton extends StatefulWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.label,
    this.iconColor = AppTheme.foregroundSecondary,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final String? label;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered ? AppTheme.surfaceTertiary : Colors.transparent,
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
                    color: widget.iconColor,
                  ),
                  if (widget.label != null) ...[
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      widget.label!,
                      style: TextStyle(
                        color: widget.iconColor,
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
