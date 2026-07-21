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
    final c = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.minus,
          size: iconSize,
          color: c.foregroundSecondary,
        ),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: c.accentPrimary,
              inactiveTrackColor: c.borderSubtle,
              thumbColor: c.accentPrimary,
              overlayColor: c.accentPrimary.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            // 뷰어의 실제 줌 범위(핀치/맞춤 배율)는 슬라이더 범위를 벗어날 수
            // 있으므로 클램프한다 — 범위 밖 값은 debug에서 assert 크래시.
            child: Slider(
              min: 25,
              max: 400,
              value: zoom.clamp(25, 400),
              onChanged: onChanged,
            ),
          ),
        ),
        Icon(
          LucideIcons.plus,
          size: iconSize,
          color: c.foregroundSecondary,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          '${zoom.round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.foregroundMuted,
          ),
        ),
      ],
    );
  }
}
