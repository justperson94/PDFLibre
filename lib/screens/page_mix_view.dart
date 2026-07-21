import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../dialogs/progress_dialog.dart';
import '../l10n/strings.dart';
import '../models/page_mix_command.dart';
import '../providers/page_mix_history_provider.dart';
import '../providers/page_mix_provider.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_open_helper.dart';
import '../widgets/page_mix/output_canvas_widget.dart';
import '../widgets/page_mix/source_tray_widget.dart';

String _shortcutPrefix() => Platform.isMacOS ? 'Cmd' : 'Ctrl';

/// 페이지 혼합 mode view — source trays on top, output canvas below.
///
/// [PageMixProvider]와 [PageMixHistoryProvider]는 MergeScreen이 소유한다.
/// 이 뷰는 모드 탭 전환 때마다 재생성되므로, 프로바이더를 여기서 만들면
/// 탭을 오갈 때 소스/출력/히스토리 상태가 사라진다. 또한 MergeScreen이
/// 소유해야 페이지 혼합 모드가 아닐 때 드롭된 파일도 소스로 추가할 수 있다.
class PageMixView extends StatelessWidget {
  const PageMixView({
    super.key,
    required this.provider,
    required this.history,
    this.initialPaths,
  });

  final PageMixProvider provider;
  final PageMixHistoryProvider history;
  final List<String>? initialPaths;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: history),
      ],
      child: _PageMixBody(initialPaths: initialPaths),
    );
  }
}

class _PageMixBody extends StatefulWidget {
  const _PageMixBody({this.initialPaths});
  final List<String>? initialPaths;

  @override
  State<_PageMixBody> createState() => _PageMixBodyState();
}

class _PageMixBodyState extends State<_PageMixBody> {
  @override
  void initState() {
    super.initState();
    if (widget.initialPaths != null && widget.initialPaths!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
    }
  }

  Future<void> _loadInitial() async {
    final provider = context.read<PageMixProvider>();
    for (final path in widget.initialPaths!) {
      if (!mounted) return;
      await provider.addSource(
        path,
        passwordProvider: makePasswordProvider(
          context,
          fileName: Uri.file(path).pathSegments.last,
          cacheKey: path,
        ),
        // PageMixProvider does not surface a per-file error UI yet; if the
        // user cancels the password prompt, addSource just resolves null and
        // the source is skipped silently — the desired behaviour.
      );
    }
  }

  Future<void> _pickFiles() async {
    final s = context.s;
    final paths = await FileService.pickMultiplePdfFiles(
      dialogTitle: s.addFiles,
    );
    if (paths.isEmpty || !mounted) return;
    final provider = context.read<PageMixProvider>();
    for (final path in paths) {
      if (!mounted) return;
      await provider.addSource(
        path,
        passwordProvider: makePasswordProvider(
          context,
          fileName: Uri.file(path).pathSegments.last,
          cacheKey: path,
        ),
        // PageMixProvider does not surface a per-file error UI yet; if the
        // user cancels the password prompt, addSource just resolves null and
        // the source is skipped silently — the desired behaviour.
      );
    }
  }

  Future<void> _merge() async {
    final s = context.s;
    final provider = context.read<PageMixProvider>();
    if (!provider.hasOutput) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.selectPagesForMerge)));
      return;
    }

    final path = await FileService.pickSaveFile(
      defaultName: '${s.merge}.pdf',
      extension: 'pdf',
      dialogTitle: s.saveDialogTitle,
    );
    if (path == null || !mounted) return;

    final refs = provider.output;
    final docs = <String, dynamic>{
      for (final src in provider.sources)
        if (provider.documentFor(src.id) != null)
          src.id: provider.documentFor(src.id)!,
    };

    final success = await runWithProgressDialog(
      context: context,
      title: s.mergingPdf,
      task: (onProgress, cancelToken) async {
        await PdfService.mergeFromPageRefsToFile(
          refs: refs,
          sourceDocuments: docs.cast(),
          outputPath: path,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? s.mergedPages(refs.length) : s.mergeError),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PageMixProvider>();
    final history = context.watch<PageMixHistoryProvider>();
    final colors = context.colors;
    final s = context.s;

    if (provider.sources.isEmpty) {
      return _EmptySources(onAddFiles: _pickFiles);
    }

    return Column(
      children: [
        // Sources area — takes all remaining vertical space, scrolls when
        // trays overflow. Trays align to top, leaving empty surfaceSecondary
        // space below when only a few sources are loaded.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              border: Border(
                bottom: BorderSide(color: colors.borderSubtle, width: 1),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: provider.sources.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacingMd),
              itemBuilder: (_, i) {
                final source = provider.sources[i];
                final doc = provider.documentFor(source.id);
                if (doc == null) return const SizedBox.shrink();
                return SourceTrayWidget(
                  source: source,
                  document: doc,
                  selection: provider.selectionFor(source.id),
                  outputCountFor: (idx) =>
                      provider.outputCountFor(source.id, idx),
                  onTogglePage: (idx) {
                    final keys = HardwareKeyboard.instance.logicalKeysPressed;
                    final shift =
                        keys.contains(LogicalKeyboardKey.shiftLeft) ||
                        keys.contains(LogicalKeyboardKey.shiftRight);
                    final modifier =
                        keys.contains(LogicalKeyboardKey.metaLeft) ||
                        keys.contains(LogicalKeyboardKey.metaRight) ||
                        keys.contains(LogicalKeyboardKey.controlLeft) ||
                        keys.contains(LogicalKeyboardKey.controlRight);
                    if (shift) {
                      provider.selectRangeFromAnchor(source.id, idx);
                    } else if (modifier) {
                      provider.togglePageSelection(source.id, idx);
                    } else {
                      provider.selectOnlyPage(source.id, idx);
                    }
                  },
                  onAddAll: () => history.execute(
                    AddToOutputCommand(
                      sourceId: source.id,
                      pageIndices: List.generate(
                        source.info.pageCount,
                        (p) => p,
                      ),
                    ),
                    provider,
                  ),
                  onAddSelection: () {
                    final sel = provider.selectionFor(source.id).toList()
                      ..sort();
                    if (sel.isEmpty) return;
                    history.execute(
                      AddToOutputCommand(sourceId: source.id, pageIndices: sel),
                      provider,
                    );
                  },
                  onAddRange: (rangeText) {
                    final indices = PdfService.parsePageRange(
                      rangeText,
                      source.info.pageCount,
                    );
                    history.execute(
                      AddToOutputCommand(
                        sourceId: source.id,
                        pageIndices: indices,
                      ),
                      provider,
                    );
                  },
                  onRemove: () {
                    provider.removeSource(source.id);
                    // 소스 제거는 되돌릴 수 없으므로(문서가 dispose됨) 남은
                    // 히스토리가 사라진 소스를 가리켜 redo로 부활시키지 않도록
                    // 스택을 비운다.
                    history.clear();
                  },
                  onSelectAll: () => provider.selectAllPages(source.id),
                  onClearSelection: () => provider.clearSelection(source.id),
                );
              },
            ),
          ),
        ),
        // Output canvas — fixed height anchored at the bottom (above the
        // action bar). 240px = 160 tile + ~22 header + ~24 vertical padding +
        // a little buffer. Stays put when sources scroll.
        SizedBox(
          height: 240,
          child: Container(
            color: colors.surfacePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: OutputCanvasWidget(
              output: provider.output,
              sources: provider.sources,
              documents: {
                for (final src in provider.sources)
                  if (provider.documentFor(src.id) != null)
                    src.id: provider.documentFor(src.id)!,
              },
              onReorder: (oldIndex, newIndex) {
                final ref = provider.output[oldIndex];
                history.execute(
                  ReorderOutputCommand(
                    instanceId: ref.instanceId,
                    oldIndex: oldIndex,
                    newIndex: newIndex,
                  ),
                  provider,
                );
              },
              onRotateCw: (ref) => history.execute(
                RotateOutputCommand(
                  instanceId: ref.instanceId,
                  clockwise: true,
                ),
                provider,
              ),
              onRotateCcw: (ref) => history.execute(
                RotateOutputCommand(
                  instanceId: ref.instanceId,
                  clockwise: false,
                ),
                provider,
              ),
              onRemove: (ref) => history.execute(
                RemoveFromOutputCommand(instanceId: ref.instanceId),
                provider,
              ),
              onClear: () => history.execute(ClearOutputCommand(), provider),
              onDropPages: (data) => history.execute(
                AddToOutputCommand(
                  sourceId: data.sourceId,
                  pageIndices: data.pageIndices,
                ),
                provider,
              ),
            ),
          ),
        ),
        // Bottom action bar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            border: Border(
              top: BorderSide(color: colors.borderSubtle, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                s.outputPageAndSourceCount(
                  provider.totalOutputPages,
                  provider.sources.length,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.foregroundSecondary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              IconButton(
                tooltip: s.undoTooltip(_shortcutPrefix()),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                onPressed: history.canUndo
                    ? () => history.undo(provider)
                    : null,
                icon: const Icon(LucideIcons.undo),
              ),
              IconButton(
                tooltip: s.redoTooltip(_shortcutPrefix()),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                onPressed: history.canRedo
                    ? () => history.redo(provider)
                    : null,
                icon: const Icon(LucideIcons.redo),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: provider.hasOutput ? _merge : null,
                icon: const Icon(LucideIcons.combine, size: 16),
                label: Text(
                  s.mergeAction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.surfacePrimary,
                  minimumSize: const Size(120, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySources extends StatelessWidget {
  const _EmptySources({required this.onAddFiles});
  final VoidCallback onAddFiles;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = context.s;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.layoutGrid, size: 48, color: colors.foregroundMuted),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            s.addFilesPrompt,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            s.addFilesHint,
            style: TextStyle(fontSize: 13, color: colors.foregroundMuted),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          FilledButton.icon(
            onPressed: onAddFiles,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(s.addFiles),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.surfacePrimary,
              minimumSize: const Size(120, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
