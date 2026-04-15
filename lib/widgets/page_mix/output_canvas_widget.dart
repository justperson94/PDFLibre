import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../l10n/strings.dart';
import '../../models/page_mix.dart';
import '../../theme/app_theme.dart';
import 'output_page_tile.dart';

/// Output canvas for the 페이지 혼합 mode.
///
/// Mirrors the Pencil `Output Canvas Area` spec: header with page/source
/// count + "출력 비우기" button, followed by a wrapping grid of
/// [OutputPageTile]s that supports drag-reordering. Empty state shows a
/// dashed drop hint area.
class OutputCanvasWidget extends StatelessWidget {
  const OutputCanvasWidget({
    super.key,
    required this.output,
    required this.sources,
    required this.documents,
    required this.onReorder,
    required this.onClear,
    this.onTileTap,
    this.selectedInstanceIds = const {},
  });

  final List<PageRef> output;
  final List<SourcePdf> sources;
  final Map<String, PdfDocument> documents;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onClear;
  final void Function(PageRef ref)? onTileTap;
  final Set<String> selectedInstanceIds;

  SourcePdf? _sourceFor(String id) {
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colors = context.colors;
    final uniqueSources = output.map((r) => r.sourceId).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  output.isEmpty
                      ? s.outputEmptyTitle
                      : s.outputPageAndSourceCount(output.length, uniqueSources),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.foregroundPrimary,
                  ),
                ),
              ),
              if (output.isNotEmpty)
                TextButton.icon(
                  onPressed: onClear,
                  icon: Icon(LucideIcons.trash2,
                      size: 14, color: colors.foregroundSecondary),
                  label: Text(
                    s.clearOutput,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.foregroundSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Expanded(
          child: output.isEmpty
              ? _EmptyState()
              : _OutputGrid(
                  output: output,
                  sourceFor: _sourceFor,
                  documents: documents,
                  onReorder: onReorder,
                  onTileTap: onTileTap,
                  selectedInstanceIds: selectedInstanceIds,
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = context.s;
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        border: Border.all(
          color: colors.borderSubtle,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.layoutGrid,
                  size: 32, color: colors.foregroundMuted),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                s.outputEmptyTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.foregroundSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.outputEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.foregroundMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutputGrid extends StatelessWidget {
  const _OutputGrid({
    required this.output,
    required this.sourceFor,
    required this.documents,
    required this.onReorder,
    required this.onTileTap,
    required this.selectedInstanceIds,
  });

  final List<PageRef> output;
  final SourcePdf? Function(String id) sourceFor;
  final Map<String, PdfDocument> documents;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(PageRef ref)? onTileTap;
  final Set<String> selectedInstanceIds;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      buildDefaultDragHandles: true,
      itemCount: output.length,
      onReorder: onReorder,
      proxyDecorator: (child, _, __) => Material(
        color: Colors.transparent,
        elevation: 6,
        child: child,
      ),
      itemBuilder: (context, index) {
        final ref = output[index];
        final source = sourceFor(ref.sourceId);
        final doc = documents[ref.sourceId];
        if (source == null || doc == null) {
          return SizedBox(
            key: ValueKey(ref.instanceId),
            width: 120,
            height: 160,
          );
        }
        final page = doc.pages[ref.pageIndex];
        final stem = _stem(source.info.fileName);
        final label = ref.rotationTurns != 0
            ? s.pageLabelRotated(
                stem,
                ref.pageIndex + 1,
                ref.rotationDegrees,
              )
            : s.pageLabelShort(stem, ref.pageIndex + 1);
        return Padding(
          key: ValueKey(ref.instanceId),
          padding: const EdgeInsets.only(right: 12),
          child: OutputPageTile(
            page: page,
            globalIndex: index + 1,
            sourceColor: source.colorTag,
            label: label,
            rotationTurns: ref.rotationTurns,
            selected: selectedInstanceIds.contains(ref.instanceId),
            onTap: onTileTap == null ? null : () => onTileTap!(ref),
          ),
        );
      },
    );
  }

  static String _stem(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }
}
