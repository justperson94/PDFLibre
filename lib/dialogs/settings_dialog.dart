import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'settings/about_section.dart';
import 'settings/defaults_section.dart';
import 'settings/general_section.dart';

/// Show the app settings dialog (3 tabs: 일반 / 파일 기본값 / 정보).
Future<void> showSettingsDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.roundedLg),
        side: BorderSide(color: context.colors.borderSubtle),
      ),
      child: SizedBox(
        width: 720,
        height: 560,
        child: Column(
          children: [
            _buildHeader(),
            Divider(height: 1, color: context.colors.borderSubtle),
            _buildTabBar(),
            Divider(height: 1, color: context.colors.borderSubtle),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  GeneralSection(),
                  DefaultsSection(),
                  AboutSection(),
                ],
              ),
            ),
            Divider(height: 1, color: context.colors.borderSubtle),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final s = context.s;
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        child: Row(
          children: [
            Text(
              s.settingsTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.colors.foregroundPrimary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.colors.surfaceTertiary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.x,
                  size: 12,
                  color: context.colors.foregroundSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final s = context.s;
    return SizedBox(
      height: 44,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        labelColor: context.colors.accentPrimary,
        unselectedLabelColor: context.colors.foregroundSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: context.colors.accentPrimary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: s.tabGeneral),
          Tab(text: s.tabDefaults),
          Tab(text: s.tabAbout),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final s = context.s;
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.accentPrimary,
                foregroundColor: context.colors.surfacePrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                ),
              ),
              child: Text(
                s.close,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
