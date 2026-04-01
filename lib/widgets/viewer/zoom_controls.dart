import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_theme.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key, required this.zoom, required this.onChanged});

  final double zoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const iconSize = 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          LucideIcons.minus,
          size: iconSize,
          color: AppTheme.foregroundSecondary,
        ),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentPrimary,
              inactiveTrackColor: AppTheme.borderSubtle,
              thumbColor: AppTheme.accentPrimary,
              overlayColor: AppTheme.accentPrimary.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(min: 25, max: 400, value: zoom, onChanged: onChanged),
          ),
        ),
        const Icon(
          LucideIcons.plus,
          size: iconSize,
          color: AppTheme.foregroundSecondary,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          '${zoom.round()}%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.foregroundMuted,
          ),
        ),
      ],
    );
  }
}
