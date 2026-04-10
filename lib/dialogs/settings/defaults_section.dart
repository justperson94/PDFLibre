import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../providers/settings_provider.dart';
import '../../services/file_service.dart';
import '../../theme/app_theme.dart';

/// 파일 기본값 section — save location mode + 3 filename rules (저장/분할/변환).
class DefaultsSection extends StatefulWidget {
  const DefaultsSection({super.key});

  @override
  State<DefaultsSection> createState() => _DefaultsSectionState();
}

class _DefaultsSectionState extends State<DefaultsSection> {
  late final TextEditingController _ruleSaveCtl;
  late final TextEditingController _ruleSplitCtl;
  late final TextEditingController _ruleConvertCtl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _ruleSaveCtl = TextEditingController(text: s.filenameRuleSave);
    _ruleSplitCtl = TextEditingController(text: s.filenameRuleSplit);
    _ruleConvertCtl = TextEditingController(text: s.filenameRuleConvert);
  }

  @override
  void dispose() {
    _ruleSaveCtl.dispose();
    _ruleSplitCtl.dispose();
    _ruleConvertCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSaveLocationSection(settings),
          const SizedBox(height: AppTheme.spacingMd),
          _buildFilenameRulesSection(settings),
          const SizedBox(height: AppTheme.spacingXl),
          _buildResetButton(context, settings),
        ],
      ),
    );
  }

  Widget _buildSaveLocationSection(SettingsProvider sp) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.saveLocation,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          s.saveLocationDesc,
          style: TextStyle(fontSize: 11, color: context.colors.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _SaveModeOption(
          label: s.askEveryTime,
          selected: sp.saveMode == SaveLocationMode.askEveryTime,
          onTap: () => sp.setSaveMode(SaveLocationMode.askEveryTime),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        _SaveModeOption(
          label: s.useFixedFolder,
          selected: sp.saveMode == SaveLocationMode.fixedFolder,
          onTap: () => sp.setSaveMode(SaveLocationMode.fixedFolder),
          trailing: _FolderPickButton(
            folderPath: sp.saveFolder,
            pickFolderLabel: s.pickFolder,
            onPick: () async {
              final dir = await FileService.pickSaveDirectory();
              if (dir != null) {
                await sp.setSaveFolder(dir);
                await sp.setSaveMode(SaveLocationMode.fixedFolder);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilenameRulesSection(SettingsProvider sp) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.filenameRules,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          s.filenameRulesDesc,
          style: TextStyle(fontSize: 11, color: context.colors.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _FilenameRuleRow(
          label: s.ruleSave,
          controller: _ruleSaveCtl,
          previewPage: null,
          onChanged: sp.setFilenameRuleSave,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _FilenameRuleRow(
          label: s.ruleSplit,
          controller: _ruleSplitCtl,
          previewPage: 3,
          onChanged: sp.setFilenameRuleSplit,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _FilenameRuleRow(
          label: s.ruleConvert,
          controller: _ruleConvertCtl,
          previewPage: 3,
          previewSuffix: '.jpg',
          onChanged: sp.setFilenameRuleConvert,
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, SettingsProvider sp) {
    final s = context.s;
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () async {
          await sp.resetOutputDefaults();
          _ruleSaveCtl.text = SettingsProvider.defaultFilenameRuleSave;
          _ruleSplitCtl.text = SettingsProvider.defaultFilenameRuleSplit;
          _ruleConvertCtl.text = SettingsProvider.defaultFilenameRuleConvert;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.resetDefaultsDone)),
            );
          }
        },
        icon: Icon(
          LucideIcons.rotateCcw,
          size: 13,
          color: context.colors.foregroundMuted,
        ),
        label: Text(
          s.resetDefaults,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.foregroundSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.colors.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
    );
  }
}

class _SaveModeOption extends StatelessWidget {
  const _SaveModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

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
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? context.colors.accentPrimary
                      : context.colors.borderSubtle,
                  width: selected ? 4 : 1.5,
                ),
                color: context.colors.surfacePrimary,
              ),
            ),
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
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _FolderPickButton extends StatelessWidget {
  const _FolderPickButton({
    required this.folderPath,
    required this.pickFolderLabel,
    required this.onPick,
  });

  final String folderPath;
  final String pickFolderLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasFolder = folderPath.isNotEmpty;
    final displayName = hasFolder
        ? folderPath.split('/').where((e) => e.isNotEmpty).last
        : pickFolderLabel;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppTheme.roundedSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.surfaceTertiary,
          borderRadius: BorderRadius.circular(AppTheme.roundedSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.folder,
              size: 12,
              color: context.colors.foregroundMuted,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Tooltip(
                message: hasFolder ? folderPath : pickFolderLabel,
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.colors.foregroundSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilenameRuleRow extends StatefulWidget {
  const _FilenameRuleRow({
    required this.label,
    required this.controller,
    required this.previewPage,
    required this.onChanged,
    this.previewSuffix = '.pdf',
  });

  final String label;
  final TextEditingController controller;
  final int? previewPage;
  final ValueChanged<String> onChanged;
  final String previewSuffix;

  @override
  State<_FilenameRuleRow> createState() => _FilenameRuleRowState();
}

class _FilenameRuleRowState extends State<_FilenameRuleRow> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onChanged(widget.controller.text);
  }

  String _preview() {
    final applied = SettingsProvider.applyFilenameRule(
      widget.controller.text,
      originalBase: 'invoice',
      pageNumber: widget.previewPage,
    );
    return '→ $applied${widget.previewSuffix}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.colors.foregroundSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.colors.surfacePrimary,
                  border: Border.all(color: context.colors.borderSubtle),
                  borderRadius: BorderRadius.circular(AppTheme.roundedSm),
                ),
                child: TextField(
                  controller: widget.controller,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.foregroundPrimary,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            SizedBox(
              width: 160,
              child: Text(
                _preview(),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: context.colors.foregroundMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
