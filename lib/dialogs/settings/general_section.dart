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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          s.themeDescription,
          style: TextStyle(fontSize: 11, color: context.colors.foregroundMuted),
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
              ),
            ),
          ],
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          s.languageDescription,
          style: TextStyle(fontSize: 11, color: context.colors.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.colors.surfacePrimary,
            border: Border.all(color: context.colors.borderSubtle),
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppLanguage>(
              value: settings.language,
              isExpanded: true,
              dropdownColor: context.colors.surfacePrimary,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: context.colors.foregroundMuted,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colors.foregroundPrimary,
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.roundedMd),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.surfaceSecondary
              : context.colors.surfacePrimary,
          border: Border.all(
            color: selected
                ? context.colors.accentPrimary
                : context.colors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? context.colors.foregroundPrimary
                      : context.colors.foregroundSecondary,
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
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.accentPrimary : context.colors.borderSubtle;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: selected ? 4 : 1.5),
        color: context.colors.surfacePrimary,
      ),
    );
  }
}
