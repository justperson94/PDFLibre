import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../dialogs/convert_dialog.dart';
import '../dialogs/error_dialog.dart';
import '../dialogs/progress_dialog.dart';
import '../dialogs/split_dialog.dart';
import '../models/edit_command.dart';
import '../providers/history_provider.dart';
import '../providers/pdf_provider.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_bar.dart';
import '../widgets/sidebar/sidebar.dart';
import '../widgets/toolbar/top_toolbar.dart';
import '../widgets/viewer/pdf_viewer.dart';
import '../widgets/viewer/viewer_toolbar.dart';
import '../widgets/viewer/zoom_controls.dart';
import 'merge_screen.dart';

/// Main screen — displayed when a PDF is open
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _viewerController = PdfViewerController();
  double _displayZoom = 100;

  @override
  void initState() {
    super.initState();
    _viewerController.addListener(_onViewerZoomChanged);
  }

  @override
  void dispose() {
    _viewerController.removeListener(_onViewerZoomChanged);
    super.dispose();
  }

  void _onViewerZoomChanged() {
    if (!_viewerController.isReady) return;
    final zoom = _viewerController.currentZoom * 100;
    if ((zoom - _displayZoom).abs() > 0.5) {
      setState(() => _displayZoom = zoom);
    }
  }

  Future<void> _openFile() async {
    final path = await FileService.pickPdfFile();
    if (path == null || !mounted) return;

    final provider = context.read<PdfProvider>();
    final success = await provider.loadPdf(path);

    if (success && mounted) {
      context.read<HistoryProvider>().clear();
    }
    if (!success && mounted) {
      showErrorDialog(context, onPickFile: _openFile);
    }
  }

  Future<void> _onSave() async {
    final pdf = context.read<PdfProvider>();
    if (pdf.pdfBytes == null) return;

    final baseName = pdf.fileName.replaceAll('.pdf', '').replaceAll('.PDF', '');
    final path = await FileService.pickSaveFile(
      defaultName: '${baseName}_편집.pdf',
      extension: 'pdf',
    );
    if (path == null || !mounted) return;

    await File(path).writeAsBytes(pdf.pdfBytes!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF 저장이 완료되었습니다')),
    );
  }

  void _rotateCurrentPage({required bool clockwise}) {
    final pdf = context.read<PdfProvider>();
    if (pdf.document == null) return;
    final originalIndex = pdf.getOriginalPageIndex(pdf.currentPage - 1);
    context.read<HistoryProvider>().execute(
      RotatePageCommand(pageIndex: originalIndex, clockwise: clockwise),
      pdf,
    );
  }

  void _undo() {
    final history = context.read<HistoryProvider>();
    if (history.canUndo) {
      history.undo(context.read<PdfProvider>());
    }
  }

  void _redo() {
    final history = context.read<HistoryProvider>();
    if (history.canRedo) {
      history.redo(context.read<PdfProvider>());
    }
  }

  Future<void> _onConvert() async {
    final result = await showConvertDialog(context);
    if (result == null || !mounted) return;

    final pdf = context.read<PdfProvider>();
    if (pdf.document == null) return;

    final success = await runWithProgressDialog(
      context: context,
      title: '이미지로 변환 중...',
      task: (onProgress, cancelToken) => PdfService.convertPagesToImages(
        document: pdf.document!,
        pageIndices: result.pageIndices,
        rotations: pdf.rotations,
        outputDir: result.outputDir,
        format: result.format,
        dpi: result.dpi.toDouble(),
        quality: result.quality,
        onProgress: onProgress,
        cancelToken: cancelToken,
      ),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${result.pageIndices.length}개 페이지를 이미지로 변환했습니다'),
        ),
      );
    }
  }

  Future<void> _onSplit() async {
    final result = await showSplitDialog(context);
    if (result == null || !mounted) return;

    final pdf = context.read<PdfProvider>();
    if (pdf.document == null) return;

    final baseName = pdf.fileName.replaceAll('.pdf', '').replaceAll('.PDF', '');

    if (result.splitIndividual) {
      final dir = await FileService.pickSaveDirectory();
      if (dir == null || !mounted) return;

      final success = await runWithProgressDialog(
        context: context,
        title: 'PDF 분할 중...',
        task: (onProgress, cancelToken) async {
          for (var i = 0; i < result.pageIndices.length; i++) {
            if (cancelToken.isCancelled) return;
            onProgress(i + 1, result.pageIndices.length);
            await PdfService.splitToFile(
              source: pdf.document!,
              pageIndices: [result.pageIndices[i]],
              rotations: pdf.rotations,
              outputPath: '$dir/${baseName}_${result.pageIndices[i] + 1}.pdf',
            );
          }
        },
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${result.pageIndices.length}개 PDF로 분할했습니다'),
          ),
        );
      }
    } else {
      final path = await FileService.pickSaveFile(
        defaultName: '${baseName}_분할.pdf',
        extension: 'pdf',
      );
      if (path == null || !mounted) return;

      final success = await runWithProgressDialog(
        context: context,
        title: 'PDF 분할 중...',
        task: (onProgress, cancelToken) async {
          onProgress(0, 1);
          await PdfService.splitToFile(
            source: pdf.document!,
            pageIndices: result.pageIndices,
            rotations: pdf.rotations,
            outputPath: path,
          );
          onProgress(1, 1);
        },
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 분할이 완료되었습니다')),
        );
      }
    }
  }

  void _zoomIn() {
    if (_viewerController.isReady) {
      _viewerController.zoomUp();
    }
  }

  void _zoomOut() {
    if (_viewerController.isReady) {
      _viewerController.zoomDown();
    }
  }

  void _setZoom(double percent) {
    if (_viewerController.isReady) {
      _viewerController.setZoom(
        _viewerController.centerPosition,
        percent / 100,
      );
    }
  }

  void _fitWidth() {
    if (!_viewerController.isReady) return;
    final page = _viewerController.pageNumber ?? 1;
    final matrix =
        _viewerController.calcMatrixFitWidthForPage(pageNumber: page);
    if (matrix != null) {
      _viewerController.goTo(matrix);
    }
  }

  void _actualSize() {
    if (_viewerController.isReady) {
      _viewerController.setZoom(
        _viewerController.centerPosition,
        1.0,
      );
    }
  }

  void _fitHeight() {
    if (!_viewerController.isReady) return;
    final page = _viewerController.pageNumber ?? 1;
    final matrix =
        _viewerController.calcMatrixFitHeightForPage(pageNumber: page);
    if (matrix != null) {
      _viewerController.goTo(matrix);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            const _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            const _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            const _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            const _RedoIntent(),
      },
      child: Actions(
        actions: {
          _UndoIntent: CallbackAction<_UndoIntent>(onInvoke: (_) {
            _undo();
            return null;
          }),
          _RedoIntent: CallbackAction<_RedoIntent>(onInvoke: (_) {
            _redo();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Consumer<PdfProvider>(
      builder: (context, pdf, _) {
        return Scaffold(
          backgroundColor: AppTheme.surfacePrimary,
          body: Column(
            children: [
              // Top toolbar (48px)
              TopToolbar(
                isGridView: pdf.isGridView,
                onViewChanged: pdf.setGridView,
                onOpenFile: _openFile,
                onClose: () {
                  pdf.closeDocument();
                  context.read<HistoryProvider>().clear();
                },
                onSave: _onSave,
                onRotateCcw: () => _rotateCurrentPage(clockwise: false),
                onRotateCw: () => _rotateCurrentPage(clockwise: true),
                onUndo: _undo,
                onRedo: _redo,
                canUndo: context.watch<HistoryProvider>().canUndo,
                canRedo: context.watch<HistoryProvider>().canRedo,
                onSplit: _onSplit,
                onMerge: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MergeScreen())),
                onConvert: _onConvert,
              ),

              // Main content: sidebar + viewer
              Expanded(
                child: Row(
                  children: [
                    // Sidebar (240px)
                    Sidebar(
                      pageCount: pdf.pageCount,
                      selectedPage: pdf.currentPage,
                      onPageSelected: pdf.setPage,
                    ),

                    // Viewer area
                    Expanded(
                      child: Column(
                        children: [
                          // Viewer sub-toolbar (36px)
                          ViewerToolbar(
                            currentPage: pdf.currentPage,
                            totalPages: pdf.pageCount,
                            zoom: _displayZoom,
                            onZoomIn: _zoomIn,
                            onZoomOut: _zoomOut,
                            onFitWidth: _fitWidth,
                            onActualSize: _actualSize,
                            onFitHeight: _fitHeight,
                            onPrev: pdf.prevPage,
                            onNext: pdf.nextPage,
                          ),

                          // PDF viewer
                          Expanded(
                            child: pdf.pdfBytes != null
                                ? PdfViewerWidget(
                                    pdfBytes: pdf.pdfBytes!,
                                    sourceName:
                                        '${pdf.fileName}_v${pdf.viewerVersion}',
                                    controller: _viewerController,
                                    currentPage: pdf.currentPage,
                                    onPageChanged: pdf.setPage,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom status bar (32px)
              StatusBar(
                leftWidget: Row(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: AppTheme.foregroundMuted,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Flexible(
                      child: Text(
                        '${pdf.fileName}  |  ${pdf.fileSize}  |  ${pdf.pageCount} 페이지',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.foregroundMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                centerText: '페이지 ${pdf.currentPage} / ${pdf.pageCount}',
                rightWidget: ZoomControls(
                  zoom: _displayZoom,
                  onChanged: _setZoom,
                ),
              ),
            ],
          ),
        );
      },
    ),
        ),
      ),
    );
  }
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}
