import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    this.leftText = '',
    this.leftWidget,
    this.centerText = '',
    this.rightText = '',
    this.rightWidget,
  });

  final String leftText;
  final Widget? leftWidget;
  final String centerText;
  final String rightText;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 12,
      color: AppTheme.foregroundMuted,
      fontWeight: FontWeight.w500,
    );

    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: AppTheme.toolbarBg,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        children: [
          Expanded(child: leftWidget ?? Text(leftText, style: textStyle)),
          Expanded(
            child: Center(
              child: Text(
                centerText,
                style: textStyle.copyWith(color: AppTheme.foregroundSecondary),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  rightWidget ??
                  Text(
                    rightText,
                    style: textStyle.copyWith(
                      color: AppTheme.foregroundSecondary,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
