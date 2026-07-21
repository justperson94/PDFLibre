import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../dialogs/progress_dialog.dart';
import '../l10n/strings.dart';
import '../providers/page_mix_history_provider.dart';
import '../providers/page_mix_provider.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_open_helper.dart';
import 'page_mix_view.dart';

/// Merge screen sub-modes.
enum _MergeMode { fileOrder, pageMix }

/// PDF merge full screen
class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key, this.initialPaths});

  final List<String>? initialPaths;

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  final _files = <_MergeFile>[];
  int _activeFileIndex = -1;
  _MergeMode _mode = _MergeMode.fileOrder;

  // 페이지 혼합 모드 상태 — 뷰가 아닌 여기서 소유해야 탭 전환에도 상태가
  // 유지되고, 혼합 모드 중 드롭된 파일을 소스 트레이로 넘길 수 있다.
  final _pageMix = PageMixProvider();
  final _pageMixHistory = PageMixHistoryProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialPaths != null && widget.initialPaths!.isNotEmpty) {
      _loadInitialFiles();
    }
  }

  bool _isDragging = false;

  Future<void> _loadInitialFiles() async {
    await _loadPaths(widget.initialPaths!);
  }

  int get _totalSelectedPages =>
      _files.fold(0, (sum, f) => sum + f.selectedPages.length);

  @override
  void dispose() {
    for (final file in _files) {
      file.document.dispose();
      // Forget the password as soon as the merge session ends, so the
      // user has to re-authenticate the file next time it is opened.
      PdfPasswordCache.remove(file.path);
    }
    // 페이지 혼합 모드의 소스들도 동일하게 암호를 잊는다.
    for (final source in _pageMix.sources) {
      PdfPasswordCache.remove(source.info.filePath);
    }
    _pageMix.dispose();
    _pageMixHistory.dispose();
    super.dispose();
  }

  /// Load PDFs from a list of file paths (shared helper)
  Future<void> _loadPaths(List<String> paths) async {
    final s = S.of(context);
    for (final path in paths) {
      final outcome = PasswordPromptOutcome();
      try {
        final bytes = await File(path).readAsBytes();
        final name = Uri.file(path).pathSegments.last;
        final doc = await PdfDocument.openData(
          bytes,
          sourceName: path,
          passwordProvider: mounted
              ? makePasswordProvider(
                  context,
                  fileName: name,
                  cacheKey: path,
                  outcome: outcome,
                )
              : null,
        );
        final size = FileService.formatFileSize(bytes.length);

        final file = _MergeFile(
          path: path,
          name: name,
          size: size,
          document: doc,
        );
        for (var i = 0; i < doc.pages.length; i++) {
          file.selectedPages.add(i);
        }
        _files.add(file);
      } catch (e) {
        // Skip the error toast when the user just cancelled the password
        // prompt — the file is simply omitted from the merge set.
        if (outcome.cancelled) continue;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.cannotOpenFilePath(path))));
        }
      }
    }

    if (_activeFileIndex < 0 && _files.isNotEmpty) {
      _activeFileIndex = 0;
    }
    if (mounted) setState(() {});
  }

  /// 페이지 혼합 모드에서 드롭된 파일을 소스 트레이로 추가한다.
  Future<void> _addPathsToPageMix(List<String> paths) async {
    for (final path in paths) {
      if (!mounted) return;
      await _pageMix.addSource(
        path,
        passwordProvider: makePasswordProvider(
          context,
          fileName: Uri.file(path).pathSegments.last,
          cacheKey: path,
        ),
      );
    }
  }

  Future<void> _addFiles() async {
    final s = S.of(context);
    final paths = await FileService.pickMultiplePdfFiles(
      dialogTitle: s.addFiles,
    );
    if (paths.isEmpty || !mounted) return;
    await _loadPaths(paths);
  }

  void _removeFile(int index) {
    final file = _files.removeAt(index);
    file.document.dispose();
    // 명시적으로 제거한 파일의 암호는 즉시 잊는다 (removeSource와 동일 규칙).
    PdfPasswordCache.remove(file.path);

    if (_files.isEmpty) {
      _activeFileIndex = -1;
    } else if (_activeFileIndex >= _files.length) {
      _activeFileIndex = _files.length - 1;
    } else if (_activeFileIndex == index) {
      _activeFileIndex = _activeFileIndex.clamp(0, _files.length - 1);
    }
    setState(() {});
  }

  Future<void> _merge() async {
    // Collect selected pages
    final pages = <PdfPage>[];
    for (final file in _files) {
      final sorted = file.selectedPages.toList()..sort();
      for (final i in sorted) {
        pages.add(file.document.pages[i]);
      }
    }

    final s = S.of(context);

    if (pages.isEmpty) {
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

    final success = await runWithProgressDialog(
      context: context,
      title: s.mergingPdf,
      task: (onProgress, cancelToken) async {
        onProgress(0, 1);
        await PdfService.mergeToFile(pages: pages, outputPath: path);
        onProgress(1, 1);
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? s.mergedPages(pages.length) : s.mergeError),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final pdfPaths = details.files
            .where((f) => f.path.toLowerCase().endsWith('.pdf'))
            .map((f) => f.path)
            .toList();
        if (pdfPaths.isEmpty) return;
        // 현재 보이는 모드로 라우팅 — 혼합 모드에서 파일 순서 목록에만
        // 추가하면 사용자에게는 드롭이 무시된 것처럼 보인다.
        if (_mode == _MergeMode.pageMix) {
          _addPathsToPageMix(pdfPaths);
        } else {
          _loadPaths(pdfPaths);
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.surfacePrimary,
        body: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(),
                Divider(height: 1, color: context.colors.borderSubtle),
                _buildModeTabs(),
                Divider(height: 1, color: context.colors.borderSubtle),
                Expanded(
                  child: _mode == _MergeMode.pageMix
                      ? PageMixView(
                          provider: _pageMix,
                          history: _pageMixHistory,
                          initialPaths: widget.initialPaths,
                        )
                      : (_files.isEmpty
                          ? _buildEmptyState()
                          : _buildContent()),
                ),
                if (_mode == _MergeMode.fileOrder) ...[
                  Divider(height: 1, color: context.colors.borderSubtle),
                  _buildBottomBar(),
                ],
              ],
            ),
            if (_isDragging)
              Container(
                color: context.colors.accentPrimary.withValues(alpha: 0.1),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.filePlus,
                        size: 48,
                        color: context.colors.accentPrimary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        s.dropFilesHere,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.accentPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTabs() {
    final s = context.s;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: context.colors.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: context.colors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildModeTab(s.modeFileOrder, _MergeMode.fileOrder),
          const SizedBox(width: 16),
          _buildModeTab(s.modePageMix, _MergeMode.pageMix),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, _MergeMode mode) {
    final active = _mode == mode;
    final colors = context.colors;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? colors.accentPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? colors.accentPrimary : colors.foregroundSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final s = context.s;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.combine,
            size: 48,
            color: context.colors.foregroundMuted,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            s.addFilesPrompt,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            s.addFilesHint,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.foregroundMuted,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          FilledButton.icon(
            onPressed: _addFiles,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(s.addFiles),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accentPrimary,
              foregroundColor: context.colors.surfacePrimary,
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

  Widget _buildContent() {
    return Row(
      children: [
        _buildFileSidebar(),
        Container(width: 1, color: context.colors.borderSubtle),
        Expanded(
          child: _activeFileIndex >= 0 && _activeFileIndex < _files.length
              ? _buildThumbnailGrid(_files[_activeFileIndex])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final s = context.s;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.toolbarBg,
        border: Border(
          bottom: BorderSide(color: context.colors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: Text(
              s.goBack,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.foregroundSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Container(width: 1, height: 24, color: context.colors.borderSubtle),
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            s.mergePdf,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.colors.foregroundPrimary,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _addFiles,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              s.addFiles,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accentPrimary,
              foregroundColor: context.colors.surfacePrimary,
              minimumSize: const Size(100, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSidebar() {
    final s = context.s;
    return Container(
      width: 280,
      color: context.colors.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.colors.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.fileList,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.foregroundPrimary,
                  ),
                ),
                Text(
                  s.fileCount(_files.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _files.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final file = _files.removeAt(oldIndex);
                  _files.insert(newIndex, file);
                  if (_activeFileIndex == oldIndex) {
                    _activeFileIndex = newIndex;
                  } else if (oldIndex < _activeFileIndex &&
                      newIndex >= _activeFileIndex) {
                    _activeFileIndex--;
                  } else if (oldIndex > _activeFileIndex &&
                      newIndex <= _activeFileIndex) {
                    _activeFileIndex++;
                  }
                });
              },
              itemBuilder: (context, i) {
                final file = _files[i];
                final active = i == _activeFileIndex;
                return ReorderableDragStartListener(
                  key: ValueKey(file.path),
                  index: i,
                  child: InkWell(
                    onTap: () => setState(() => _activeFileIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingMd,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? context.colors.accentPrimary
                            : Colors.transparent,
                        border: active
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: context.colors.borderSubtle,
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          // Drag handle — same pattern as sidebar PageThumbnail
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppTheme.spacingXs,
                            ),
                            child: Icon(
                              LucideIcons.gripVertical,
                              size: 14,
                              color: active
                                  ? context.colors.surfacePrimary.withValues(
                                      alpha: 0.7,
                                    )
                                  : context.colors.foregroundMuted,
                            ),
                          ),
                          // First page thumbnail
                          Container(
                            width: 36,
                            height: 48,
                            decoration: BoxDecoration(
                              color: context.colors.surfacePrimary,
                              borderRadius: BorderRadius.circular(
                                AppTheme.roundedSm,
                              ),
                              border: Border.all(
                                color: active
                                    ? context.colors.surfacePrimary.withValues(
                                        alpha: 0.5,
                                      )
                                    : context.colors.borderSubtle,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _PageGridThumbnail(
                              page: file.document.pages.first,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: active
                                        ? context.colors.surfacePrimary
                                        : context.colors.foregroundPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.filePageInfo(
                                    file.document.pages.length,
                                    file.size,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: active
                                        ? context.colors.surfacePrimary.withValues(
                                            alpha: 0.7,
                                          )
                                        : context.colors.foregroundMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Remove button
                          IconButton(
                            onPressed: () => _removeFile(i),
                            icon: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: active
                                  ? context.colors.surfacePrimary.withValues(
                                      alpha: 0.7,
                                    )
                                  : context.colors.foregroundMuted,
                            ),
                            iconSize: 16,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: s.removeFile,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailGrid(_MergeFile file) {
    final s = context.s;
    final pageCount = file.document.pages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXl,
            vertical: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.colors.borderSubtle, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                s.filePageSelection(file.name),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.foregroundPrimary,
                ),
              ),
              const Spacer(),
              Checkbox(
                value: file.selectedPages.length == pageCount
                    ? true
                    : file.selectedPages.isEmpty
                    ? false
                    : null,
                tristate: true,
                onChanged: (v) {
                  setState(() {
                    if (file.selectedPages.length == pageCount) {
                      file.selectedPages.clear();
                    } else {
                      file.selectedPages.clear();
                      for (var i = 0; i < pageCount; i++) {
                        file.selectedPages.add(i);
                      }
                    }
                  });
                },
                activeColor: context.colors.accentPrimary,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                s.selectAll,
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppTheme.spacingLg,
              mainAxisSpacing: AppTheme.spacingLg,
              childAspectRatio: 0.65,
            ),
            itemCount: pageCount,
            itemBuilder: (context, index) {
              final selected = file.selectedPages.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      file.selectedPages.remove(index);
                    } else {
                      file.selectedPages.add(index);
                    }
                  });
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.surfacePrimary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.roundedSm,
                          ),
                          border: Border.all(
                            color: selected
                                ? context.colors.accentPrimary
                                : context.colors.borderSubtle,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // PDF page thumbnail
                            Positioned.fill(
                              child: _PageGridThumbnail(
                                page: file.document.pages[index],
                              ),
                            ),
                            // Checkbox
                            Positioned(
                              top: AppTheme.spacingXs,
                              left: AppTheme.spacingXs,
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        file.selectedPages.add(index);
                                      } else {
                                        file.selectedPages.remove(index);
                                      }
                                    });
                                  },
                                  activeColor: context.colors.accentPrimary,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final s = context.s;
    final totalPages = _files.fold(
      0,
      (sum, f) => sum + f.document.pages.length,
    );
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: context.colors.toolbarBg,
        border: Border(top: BorderSide(color: context.colors.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            s.selectedPages(_totalSelectedPages, totalPages),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.foregroundSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXl),
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 14,
                color: context.colors.foregroundMuted,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                s.originalUnchanged,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.foregroundMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _files.isEmpty ? null : _merge,
            icon: const Icon(LucideIcons.combine, size: 16),
            label: Text(
              s.mergeAction,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accentPrimary,
              foregroundColor: context.colors.surfacePrimary,
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

/// PDF page thumbnail for merge screen grid
class _PageGridThumbnail extends StatefulWidget {
  const _PageGridThumbnail({required this.page});
  final PdfPage page;

  @override
  State<_PageGridThumbnail> createState() => _PageGridThumbnailState();
}

class _PageGridThumbnailState extends State<_PageGridThumbnail> {
  ui.Image? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(_PageGridThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _image?.dispose();
      _image = null;
      _render();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _render() async {
    if (_loading) return;
    _loading = true;
    try {
      const thumbWidth = 300.0;
      final scale = thumbWidth / widget.page.width;
      final thumbHeight = widget.page.height * scale;

      final pdfImage = await widget.page.render(
        fullWidth: thumbWidth,
        fullHeight: thumbHeight,
      );
      if (pdfImage == null || !mounted) {
        pdfImage?.dispose();
        return;
      }

      final image = await pdfImage.createImage();
      pdfImage.dispose();

      if (mounted) {
        setState(() => _image = image);
      } else {
        image.dispose();
      }
    } catch (_) {
      // Keep placeholder on render failure
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return RawImage(image: _image, fit: BoxFit.contain);
    }
    return Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: context.colors.foregroundMuted,
        ),
      ),
    );
  }
}

class _MergeFile {
  _MergeFile({
    required this.path,
    required this.name,
    required this.size,
    required this.document,
  });

  final String path;
  final String name;
  final String size;
  final PdfDocument document;
  final selectedPages = <int>{}; // 0-based page indices
}
