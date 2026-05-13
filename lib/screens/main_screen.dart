import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../dialogs/convert_dialog.dart';
import '../dialogs/error_dialog.dart';
import '../dialogs/progress_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/split_dialog.dart';
import '../l10n/strings.dart';
import '../models/edit_command.dart';
import '../providers/history_provider.dart';
import '../providers/pdf_provider.dart';
import '../providers/settings_provider.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../services/recent_files_service.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_open_helper.dart';
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
    final s = S.of(context);
    final path = await FileService.pickPdfFile(dialogTitle: s.pickPdfFile);
    if (path == null || !mounted) return;

    final provider = context.read<PdfProvider>();
    final result = await loadPdfInteractive(context, provider, path);
    if (!mounted) return;

    switch (result) {
      case PdfOpenResult.success:
        context.read<HistoryProvider>().clear();
        RecentFilesService.add(path);
      case PdfOpenResult.cancelled:
        // Silent — user dismissed the password prompt.
        break;
      case PdfOpenResult.error:
        showErrorDialog(context, onPickFile: _openFile);
    }
  }

  Future<void> _onSave() async {
    final s = S.of(context);
    final pdf = context.read<PdfProvider>();
    if (pdf.pdfBytes == null) return;

    final settings = context.read<SettingsProvider>();
    final baseName = _stripPdfExtension(pdf.fileName);
    final defaultName = SettingsProvider.applyFilenameRule(
      settings.filenameRuleSave,
      originalBase: baseName,
    );
    final path = await FileService.pickSaveFile(
      defaultName: '$defaultName.pdf',
      extension: 'pdf',
      initialDirectoryOverride:
          settings.saveMode == SaveLocationMode.fixedFolder
          ? settings.saveFolder
          : null,
    );
    if (path == null || !mounted) return;

    try {
      await File(path).writeAsBytes(pdf.pdfBytes!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.saveFailed(e.toString()))));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.saveComplete)));
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

  Future<void> _confirmClose() async {
    final s = S.of(context);
    final hasChanges = context.read<HistoryProvider>().canUndo;
    if (hasChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.colors.surfacePrimary,
          title: Text(s.closeDocTitle),
          content: Text(s.unsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: ctx.colors.danger),
              child: Text(s.close),
            ),
          ],
        ),
      );
      if (result != true || !mounted) return;
    }
    if (!mounted) return;
    context.read<PdfProvider>().closeDocument();
    context.read<HistoryProvider>().clear();
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

  void _openSettings() {
    showSettingsDialog(context);
  }

  Future<void> _onConvert() async {
    final s = S.of(context);
    final result = await showConvertDialog(context);
    if (result == null || !mounted) return;

    final pdf = context.read<PdfProvider>();
    if (pdf.document == null) return;

    final settings = context.read<SettingsProvider>();
    final baseName = _stripPdfExtension(pdf.fileName);
    final success = await runWithProgressDialog(
      context: context,
      title: s.convertingImages,
      task: (onProgress, cancelToken) => PdfService.convertPagesToImages(
        document: pdf.document!,
        pageIndices: result.pageIndices,
        rotations: pdf.rotations,
        outputDir: result.outputDir,
        format: result.format,
        dpi: result.dpi.toDouble(),
        quality: result.quality,
        fileNameBuilder: (pageNumber) => SettingsProvider.applyFilenameRule(
          settings.filenameRuleConvert,
          originalBase: baseName,
          pageNumber: pageNumber,
        ),
        onProgress: onProgress,
        cancelToken: cancelToken,
      ),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.convertedPages(result.pageIndices.length))),
      );
    }
  }

  Future<void> _onSplit() async {
    final s = S.of(context);
    final result = await showSplitDialog(context);
    if (result == null || !mounted) return;

    final pdf = context.read<PdfProvider>();
    if (pdf.document == null) return;

    final settings = context.read<SettingsProvider>();
    final baseName = _stripPdfExtension(pdf.fileName);
    final fixedDir = settings.saveMode == SaveLocationMode.fixedFolder
        ? settings.saveFolder
        : null;

    if (result.splitIndividual) {
      final dir = await FileService.pickSaveDirectory();
      if (dir == null || !mounted) return;

      final success = await runWithProgressDialog(
        context: context,
        title: s.splittingPdf,
        task: (onProgress, cancelToken) async {
          for (var i = 0; i < result.pageIndices.length; i++) {
            if (cancelToken.isCancelled) return;
            onProgress(i + 1, result.pageIndices.length);
            final pageNum = result.pageIndices[i] + 1;
            final fileName = SettingsProvider.applyFilenameRule(
              settings.filenameRuleSplit,
              originalBase: baseName,
              pageNumber: pageNum,
            );
            await PdfService.splitToFile(
              source: pdf.document!,
              pageIndices: [result.pageIndices[i]],
              rotations: pdf.rotations,
              outputPath: '$dir/$fileName.pdf',
            );
          }
        },
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.splitComplete(result.pageIndices.length))),
        );
      }
    } else {
      // Single combined PDF: rule uses first selected page number.
      final firstPage =
          (result.pageIndices.isNotEmpty ? result.pageIndices.first : 0) + 1;
      final defaultName = SettingsProvider.applyFilenameRule(
        settings.filenameRuleSplit,
        originalBase: baseName,
        pageNumber: firstPage,
      );
      final path = await FileService.pickSaveFile(
        defaultName: '$defaultName.pdf',
        extension: 'pdf',
        initialDirectoryOverride: fixedDir,
      );
      if (path == null || !mounted) return;

      final success = await runWithProgressDialog(
        context: context,
        title: s.splittingPdf,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.splitSingleComplete)));
      }
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
    final matrix = _viewerController.calcMatrixFitWidthForPage(
      pageNumber: page,
    );
    if (matrix != null) {
      _viewerController.goTo(matrix);
    }
  }

  void _actualSize() {
    if (_viewerController.isReady) {
      _viewerController.setZoom(_viewerController.centerPosition, 1.0);
    }
  }

  void _fitHeight() {
    if (!_viewerController.isReady) return;
    final page = _viewerController.pageNumber ?? 1;
    final matrix = _viewerController.calcMatrixFitHeightForPage(
      pageNumber: page,
    );
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
        SingleActivator(LogicalKeyboardKey.keyO, meta: true):
            const _OpenIntent(),
        SingleActivator(LogicalKeyboardKey.keyO, control: true):
            const _OpenIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            const _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyW, meta: true):
            const _CloseIntent(),
        SingleActivator(LogicalKeyboardKey.keyW, control: true):
            const _CloseIntent(),
        SingleActivator(LogicalKeyboardKey.comma, meta: true):
            const _SettingsIntent(),
        SingleActivator(LogicalKeyboardKey.comma, control: true):
            const _SettingsIntent(),
      },
      child: Actions(
        actions: {
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              _undo();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              _redo();
              return null;
            },
          ),
          _OpenIntent: CallbackAction<_OpenIntent>(
            onInvoke: (_) {
              _openFile();
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              _onSave();
              return null;
            },
          ),
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) {
              _confirmClose();
              return null;
            },
          ),
          _SettingsIntent: CallbackAction<_SettingsIntent>(
            onInvoke: (_) {
              _openSettings();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Consumer<PdfProvider>(
            builder: (context, pdf, _) {
              final s = context.s;
              return Scaffold(
                backgroundColor: context.colors.surfacePrimary,
                body: Column(
                  children: [
                    // Top toolbar (48px)
                    TopToolbar(
                      onOpenFile: _openFile,
                      onClose: _confirmClose,
                      onSave: _onSave,
                      onRotateCcw: () => _rotateCurrentPage(clockwise: false),
                      onRotateCw: () => _rotateCurrentPage(clockwise: true),
                      onUndo: _undo,
                      onRedo: _redo,
                      canUndo: context.watch<HistoryProvider>().canUndo,
                      canRedo: context.watch<HistoryProvider>().canRedo,
                      onSplit: _onSplit,
                      onMerge: () {
                        final currentPath = context
                            .read<PdfProvider>()
                            .originalFilePath;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MergeScreen(
                              initialPaths: currentPath.isNotEmpty
                                  ? [currentPath]
                                  : null,
                            ),
                          ),
                        );
                      },
                      onConvert: _onConvert,
                      onSettings: _openSettings,
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
                                          passwordProvider:
                                              pdf.viewerPasswordProvider,
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
                          Icon(
                            LucideIcons.fileText,
                            size: 14,
                            color: context.colors.foregroundMuted,
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Flexible(
                            child: Tooltip(
                              message: pdf.fileName,
                              child: Text(
                                pdf.fileName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.foregroundMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            s.statusInfo(pdf.fileSize, pdf.pageCount),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.foregroundMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      centerText: '',
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

String _stripPdfExtension(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.pdf')) {
    return fileName.substring(0, fileName.length - 4);
  }
  return fileName;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _OpenIntent extends Intent {
  const _OpenIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}
