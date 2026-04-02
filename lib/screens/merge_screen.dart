import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../dialogs/progress_dialog.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

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
    }
    super.dispose();
  }

  /// Load PDFs from a list of file paths (shared helper)
  Future<void> _loadPaths(List<String> paths) async {
    for (final path in paths) {
      try {
        final bytes = await File(path).readAsBytes();
        final doc = await PdfDocument.openData(bytes, sourceName: path);
        final name = Uri.file(path).pathSegments.last;
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
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('파일을 열 수 없습니다: $path')));
        }
      }
    }

    if (_activeFileIndex < 0 && _files.isNotEmpty) {
      _activeFileIndex = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _addFiles() async {
    final paths = await FileService.pickMultiplePdfFiles();
    if (paths.isEmpty || !mounted) return;
    await _loadPaths(paths);
  }

  void _removeFile(int index) {
    final file = _files.removeAt(index);
    file.document.dispose();

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

    if (pages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('병합할 페이지를 선택해주세요')));
      return;
    }

    final path = await FileService.pickSaveFile(
      defaultName: '병합.pdf',
      extension: 'pdf',
    );
    if (path == null || !mounted) return;

    final success = await runWithProgressDialog(
      context: context,
      title: 'PDF 병합 중...',
      task: (onProgress, cancelToken) async {
        onProgress(0, 1);
        await PdfService.mergeToFile(pages: pages, outputPath: path);
        onProgress(1, 1);
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '${pages.length}개 페이지를 병합했습니다' : '병합 중 오류가 발생했습니다',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final pdfPaths = details.files
            .where((f) => f.path.toLowerCase().endsWith('.pdf'))
            .map((f) => f.path)
            .toList();
        if (pdfPaths.isNotEmpty) _loadPaths(pdfPaths);
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfacePrimary,
        body: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(),
                const Divider(height: 1, color: AppTheme.borderSubtle),
                Expanded(
                  child:
                      _files.isEmpty ? _buildEmptyState() : _buildContent(),
                ),
                const Divider(height: 1, color: AppTheme.borderSubtle),
                _buildBottomBar(),
              ],
            ),
            if (_isDragging)
              Container(
                color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.filePlus,
                        size: 48,
                        color: AppTheme.accentPrimary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'PDF 파일을 여기에 놓으세요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              AppTheme.accentPrimary.withValues(alpha: 0.7),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.combine,
            size: 48,
            color: AppTheme.foregroundMuted,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const Text(
            '병합할 PDF 파일을 추가해주세요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const Text(
            '상단의 "파일 추가" 버튼으로 여러 PDF를 선택할 수 있습니다',
            style: TextStyle(fontSize: 13, color: AppTheme.foregroundMuted),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          FilledButton.icon(
            onPressed: _addFiles,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('파일 추가'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.surfacePrimary,
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
        Container(width: 1, color: AppTheme.borderSubtle),
        Expanded(
          child: _activeFileIndex >= 0 && _activeFileIndex < _files.length
              ? _buildThumbnailGrid(_files[_activeFileIndex])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      decoration: const BoxDecoration(
        color: AppTheme.toolbarBg,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text(
              '돌아가기',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.foregroundSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          const SizedBox(width: AppTheme.spacingMd),
          const Text(
            'PDF 병합',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundPrimary,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _addFiles,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text(
              '파일 추가',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.surfacePrimary,
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
    return Container(
      width: 280,
      color: AppTheme.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '파일 목록',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foregroundPrimary,
                  ),
                ),
                Text(
                  '${_files.length}개 파일',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.foregroundMuted,
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
                            ? AppTheme.accentPrimary
                            : Colors.transparent,
                        border: active
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                  color: AppTheme.borderSubtle,
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          // First page thumbnail
                          Container(
                            width: 36,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.surfacePrimary,
                              borderRadius: BorderRadius.circular(
                                AppTheme.roundedSm,
                              ),
                              border: Border.all(
                                color: active
                                    ? AppTheme.surfacePrimary
                                        .withValues(alpha: 0.5)
                                    : AppTheme.borderSubtle,
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
                                        ? AppTheme.surfacePrimary
                                        : AppTheme.foregroundPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${file.document.pages.length} 페이지 · ${file.size}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: active
                                        ? AppTheme.surfacePrimary.withValues(
                                            alpha: 0.7,
                                          )
                                        : AppTheme.foregroundMuted,
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
                                  ? AppTheme.surfacePrimary.withValues(
                                      alpha: 0.7,
                                    )
                                  : AppTheme.foregroundMuted,
                            ),
                            iconSize: 16,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: '파일 제거',
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
    final pageCount = file.document.pages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXl,
            vertical: AppTheme.spacingMd,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${file.name} — 페이지 선택',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foregroundPrimary,
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
                activeColor: AppTheme.accentPrimary,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                '전체 선택',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.foregroundSecondary,
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
                          color: AppTheme.surfacePrimary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.roundedSm,
                          ),
                          border: Border.all(
                            color: selected
                                ? AppTheme.accentPrimary
                                : AppTheme.borderSubtle,
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
                                  activeColor: AppTheme.accentPrimary,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.foregroundMuted,
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
    final totalPages = _files.fold(
      0,
      (sum, f) => sum + f.document.pages.length,
    );
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      decoration: const BoxDecoration(
        color: AppTheme.toolbarBg,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            '선택된 페이지: $_totalSelectedPages / $totalPages',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXl),
          Row(
            children: const [
              Icon(LucideIcons.info, size: 14, color: AppTheme.foregroundMuted),
              SizedBox(width: AppTheme.spacingXs),
              Text(
                '원본 파일은 변경되지 않습니다',
                style: TextStyle(fontSize: 12, color: AppTheme.foregroundMuted),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _files.isEmpty ? null : _merge,
            icon: const Icon(LucideIcons.combine, size: 16),
            label: const Text(
              '병합하기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.surfacePrimary,
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
    return const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppTheme.foregroundMuted,
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
