import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

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
        ],
      ),
    );
  }

  Widget _buildSaveLocationSection(SettingsProvider s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '저장 위치',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        const Text(
          '저장 다이얼로그에서 처음 열리는 폴더를 지정합니다',
          style: TextStyle(fontSize: 11, color: AppTheme.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _SaveModeOption(
          label: '매번 묻기 (현재 동작)',
          selected: s.saveMode == SaveLocationMode.askEveryTime,
          onTap: () => s.setSaveMode(SaveLocationMode.askEveryTime),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        _SaveModeOption(
          label: '지정한 폴더 사용',
          selected: s.saveMode == SaveLocationMode.fixedFolder,
          onTap: () => s.setSaveMode(SaveLocationMode.fixedFolder),
          trailing: _FolderPickButton(
            folderPath: s.saveFolder,
            onPick: () async {
              final dir = await FileService.pickSaveDirectory();
              if (dir != null) {
                await s.setSaveFolder(dir);
                await s.setSaveMode(SaveLocationMode.fixedFolder);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilenameRulesSection(SettingsProvider s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '파일명 규칙',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        const Text(
          '각 작업에서 생성되는 기본 파일명 규칙. 토큰: {원본} {페이지} {날짜}',
          style: TextStyle(fontSize: 11, color: AppTheme.foregroundMuted),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _FilenameRuleRow(
          label: '저장',
          controller: _ruleSaveCtl,
          previewPage: null,
          onChanged: s.setFilenameRuleSave,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _FilenameRuleRow(
          label: '분할',
          controller: _ruleSplitCtl,
          previewPage: 3,
          onChanged: s.setFilenameRuleSplit,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _FilenameRuleRow(
          label: '이미지 변환',
          controller: _ruleConvertCtl,
          previewPage: 3,
          previewSuffix: '.jpg',
          onChanged: s.setFilenameRuleConvert,
        ),
      ],
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
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppTheme.accentPrimary
                      : AppTheme.borderSubtle,
                  width: selected ? 4 : 1.5,
                ),
                color: AppTheme.surfacePrimary,
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
                      ? AppTheme.foregroundPrimary
                      : AppTheme.foregroundSecondary,
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
  const _FolderPickButton({required this.folderPath, required this.onPick});

  final String folderPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasFolder = folderPath.isNotEmpty;
    final displayName = hasFolder
        ? folderPath.split('/').where((e) => e.isNotEmpty).last
        : '폴더 선택';
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppTheme.roundedSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTertiary,
          borderRadius: BorderRadius.circular(AppTheme.roundedSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.folder,
              size: 12,
              color: AppTheme.foregroundMuted,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Tooltip(
                message: hasFolder ? folderPath : '폴더 선택',
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundSecondary,
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.foregroundSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfacePrimary,
                  border: Border.all(color: AppTheme.borderSubtle),
                  borderRadius: BorderRadius.circular(AppTheme.roundedSm),
                ),
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.foregroundPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            SizedBox(
              width: 160,
              child: Text(
                _preview(),
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.foregroundMuted,
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
