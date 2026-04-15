import 'package:flutter/material.dart';
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
import '../widgets/page_mix/output_canvas_widget.dart';
import '../widgets/page_mix/source_tray_widget.dart';

/// 페이지 혼합 mode view — source trays on top, output canvas below.
///
/// Owns its own [PageMixProvider] + [PageMixHistoryProvider] so that the
/// mix state is independent from the "파일 순서" mode and is cleaned up on
/// unmount.
class PageMixView extends StatelessWidget {
  const PageMixView({super.key, this.initialPaths});

  final List<String>? initialPaths;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PageMixProvider()),
        ChangeNotifierProvider(create: (_) => PageMixHistoryProvider()),
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
      await provider.addSource(path);
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
      await provider.addSource(path);
    }
  }

  Future<void> _merge() async {
    final s = context.s;
    final provider = context.read<PageMixProvider>();
    if (!provider.hasOutput) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.selectPagesForMerge)),
      );
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
        onProgress(0, 1);
        await PdfService.mergeFromPageRefsToFile(
          refs: refs,
          sourceDocuments: docs.cast(),
          outputPath: path,
        );
        onProgress(1, 1);
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
        // Sources area
        Container(
          constraints: const BoxConstraints(maxHeight: 340),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            border: Border(
              bottom: BorderSide(color: colors.borderSubtle, width: 1),
            ),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
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
                onTogglePage: (idx) =>
                    provider.togglePageSelection(source.id, idx),
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
                  final sel = provider.selectionFor(source.id).toList()..sort();
                  if (sel.isEmpty) return;
                  history.execute(
                    AddToOutputCommand(
                      sourceId: source.id,
                      pageIndices: sel,
                    ),
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
                onRemove: () => provider.removeSource(source.id),
              );
            },
          ),
        ),
        // Output canvas
        Expanded(
          child: Container(
            color: colors.surfacePrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
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
              onClear: provider.clearOutput,
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
          Icon(
            LucideIcons.layoutGrid,
            size: 48,
            color: colors.foregroundMuted,
          ),
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
            style: TextStyle(
              fontSize: 13,
              color: colors.foregroundMuted,
            ),
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
