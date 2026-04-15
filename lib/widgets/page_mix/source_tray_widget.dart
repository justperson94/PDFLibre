import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../l10n/strings.dart';
import '../../models/page_mix.dart';
import '../../theme/app_theme.dart';
import 'page_thumbnail_tile.dart';

/// Collapsible source tray for the 페이지 혼합 mode.
///
/// Mirrors the Pencil `Source Tray` spec: color-dotted header with file
/// meta + selection badge; range input, "전체 추가" button, collapse toggle;
/// expandable horizontal strip of [PageThumbnailTile]s.
class SourceTrayWidget extends StatefulWidget {
  const SourceTrayWidget({
    super.key,
    required this.source,
    required this.document,
    required this.selection,
    required this.onTogglePage,
    required this.onAddAll,
    required this.onAddSelection,
    required this.onAddRange,
    required this.onRemove,
    required this.onSelectAll,
    required this.onClearSelection,
    this.initiallyExpanded = true,
  });

  final SourcePdf source;
  final PdfDocument document;
  final Set<int> selection;
  final void Function(int pageIndex) onTogglePage;
  final VoidCallback onAddAll;
  final VoidCallback onAddSelection;
  final void Function(String rangeText) onAddRange;
  final VoidCallback onRemove;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool initiallyExpanded;

  @override
  State<SourceTrayWidget> createState() => _SourceTrayWidgetState();
}

class _SourceTrayWidgetState extends State<SourceTrayWidget> {
  late bool _expanded = widget.initiallyExpanded;
  final _rangeController = TextEditingController();
  String? _rangeError;

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  void _submitRange() {
    final text = _rangeController.text.trim();
    if (text.isEmpty) return;
    try {
      widget.onAddRange(text);
      _rangeController.clear();
      setState(() => _rangeError = null);
    } catch (e) {
      setState(() => _rangeError = context.s.invalidRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = context.s;
    final info = widget.source.info;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            const _SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            const _SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _ClearSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const _AppendSelectionIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SelectAllIntent: CallbackAction<_SelectAllIntent>(
            onInvoke: (_) {
              widget.onSelectAll();
              return null;
            },
          ),
          _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
            onInvoke: (_) {
              widget.onClearSelection();
              return null;
            },
          ),
          _AppendSelectionIntent: CallbackAction<_AppendSelectionIntent>(
            onInvoke: (_) {
              if (widget.selection.isNotEmpty) widget.onAddSelection();
              return null;
            },
          ),
        },
        child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppTheme.roundedSm * 2),
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _ColorDot(color: widget.source.colorTag),
                    Text(
                      info.fileName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.foregroundPrimary,
                      ),
                    ),
                    Text(
                      s.pageMeta(info.pageCount, info.fileSize),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.foregroundMuted,
                      ),
                    ),
                    if (widget.selection.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.selectedCount(widget.selection.length),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.foregroundSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _RangeInput(
                controller: _rangeController,
                hintText: s.rangeInputHint,
                errorText: _rangeError,
                onSubmitted: _submitRange,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              if (widget.selection.isNotEmpty)
                _TrayActionButton(
                  icon: LucideIcons.listPlus,
                  label: s.addSelection,
                  onTap: widget.onAddSelection,
                  filled: false,
                ),
              if (widget.selection.isNotEmpty)
                const SizedBox(width: AppTheme.spacingXs),
              _TrayActionButton(
                icon: LucideIcons.plus,
                label: s.addAll,
                onTap: widget.onAddAll,
                filled: true,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              IconButton(
                tooltip: _expanded ? s.collapseTray : s.expandTray,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                color: colors.foregroundMuted,
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                ),
              ),
              IconButton(
                tooltip: s.removeSource,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                color: colors.foregroundMuted,
                onPressed: widget.onRemove,
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _ThumbnailStrip(
              source: widget.source,
              document: widget.document,
              selection: widget.selection,
              onTogglePage: widget.onTogglePage,
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

class _AppendSelectionIntent extends Intent {
  const _AppendSelectionIntent();
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RangeInput extends StatelessWidget {
  const _RangeInput({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 11, color: colors.foregroundPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 11, color: colors.foregroundMuted),
          errorText: errorText,
          errorStyle: TextStyle(fontSize: 10, color: colors.danger),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          filled: true,
          fillColor: colors.surfaceSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            borderSide: BorderSide(color: colors.borderSubtle, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            borderSide: BorderSide(color: colors.borderSubtle, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
          ),
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}

class _TrayActionButton extends StatelessWidget {
  const _TrayActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = filled ? colors.accentPrimary : colors.surfaceSecondary;
    final fg = filled ? colors.surfacePrimary : colors.foregroundSecondary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.roundedMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.source,
    required this.document,
    required this.selection,
    required this.onTogglePage,
  });

  final SourcePdf source;
  final PdfDocument document;
  final Set<int> selection;
  final void Function(int pageIndex) onTogglePage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: source.info.pageCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
        itemBuilder: (_, i) {
          return PageThumbnailTile(
            page: document.pages[i],
            selected: selection.contains(i),
            sourceColor: source.colorTag,
            onTap: () => onTogglePage(i),
          );
        },
      ),
    );
  }
}
