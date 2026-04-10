import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

/// 일반 section — theme mode + language selection.
///
/// Theme (light/dark) and language (English) are wired but gated behind
/// Phase 4 — the app currently only ships light-mode Korean. The UI is
/// live so the settings persist and are ready to wire to MaterialApp later.
class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSection(context, settings),
          const SizedBox(height: AppTheme.spacingXl),
          _buildLanguageSection(context, settings),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, SettingsProvider settings) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.theme,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          s.themeDescription,
          style: const TextStyle(fontSize: 11, color: AppTheme.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _ThemeOption(
                label: s.themeSystem,
                selected: settings.themeMode == AppThemeMode.system,
                onTap: () => settings.setThemeMode(AppThemeMode.system),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: _ThemeOption(
                label: s.themeLight,
                selected: settings.themeMode == AppThemeMode.light,
                onTap: () => settings.setThemeMode(AppThemeMode.light),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: _ThemeOption(
                label: s.themeDark,
                selected: settings.themeMode == AppThemeMode.dark,
                onTap: () => settings.setThemeMode(AppThemeMode.dark),
                disabled: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceTertiary,
            borderRadius: BorderRadius.circular(AppTheme.roundedSm),
          ),
          child: Text(
            s.darkModePhase4,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.foregroundMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.language,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          s.languageDescription,
          style: const TextStyle(fontSize: 11, color: AppTheme.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfacePrimary,
            border: Border.all(color: AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppLanguage>(
              value: settings.language,
              isExpanded: true,
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.foregroundMuted,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.foregroundPrimary,
              ),
              items: const [
                DropdownMenuItem(value: AppLanguage.ko, child: Text('한국어')),
                DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) settings.setLanguage(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.roundedMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surfaceSecondary : AppTheme.surfacePrimary,
          border: Border.all(
            color: selected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected, disabled: disabled),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: disabled
                      ? AppTheme.foregroundMuted
                      : (selected
                            ? AppTheme.foregroundPrimary
                            : AppTheme.foregroundSecondary),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.disabled});

  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? AppTheme.foregroundMuted
        : (selected ? AppTheme.accentPrimary : AppTheme.borderSubtle);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: selected ? 4 : 1.5),
        color: AppTheme.surfacePrimary,
      ),
    );
  }
}
