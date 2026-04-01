import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../dialogs/convert_dialog.dart';
import '../dialogs/error_dialog.dart';
import '../dialogs/progress_dialog.dart';
import '../dialogs/split_dialog.dart';
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

/// 메인 화면 — PDF가 열려 있을 때 표시
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

    if (!success && mounted) {
      showErrorDialog(context, onPickFile: _openFile);
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
      task: (onProgress) => PdfService.convertPagesToImages(
        document: pdf.document!,
        pageIndices: result.pageIndices,
        outputDir: result.outputDir,
        format: result.format,
        dpi: result.dpi.toDouble(),
        quality: result.quality,
        onProgress: onProgress,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${result.pageIndices.length}개 페이지를 이미지로 변환했습니다'
              : '변환 중 오류가 발생했습니다',
        ),
      ),
    );
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
        task: (onProgress) async {
          for (var i = 0; i < result.pageIndices.length; i++) {
            onProgress(i + 1, result.pageIndices.length);
            await PdfService.splitToFile(
              source: pdf.document!,
              pageIndices: [result.pageIndices[i]],
              outputPath: '$dir/${baseName}_${result.pageIndices[i] + 1}.pdf',
            );
          }
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${result.pageIndices.length}개 PDF로 분할했습니다'
                : '분할 중 오류가 발생했습니다',
          ),
        ),
      );
    } else {
      final path = await FileService.pickSaveFile(
        defaultName: '${baseName}_분할.pdf',
        extension: 'pdf',
      );
      if (path == null || !mounted) return;

      final success = await runWithProgressDialog(
        context: context,
        title: 'PDF 분할 중...',
        task: (onProgress) async {
          onProgress(0, 1);
          await PdfService.splitToFile(
            source: pdf.document!,
            pageIndices: result.pageIndices,
            outputPath: path,
          );
          onProgress(1, 1);
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'PDF 분할이 완료되었습니다' : '분할 중 오류가 발생했습니다'),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfProvider>(
      builder: (context, pdf, _) {
        return Scaffold(
          backgroundColor: AppTheme.surfacePrimary,
          body: Column(
            children: [
              // 상단 툴바 (48px)
              TopToolbar(
                isGridView: pdf.isGridView,
                onViewChanged: pdf.setGridView,
                onOpenFile: _openFile,
                onClose: pdf.closeDocument,
                onRotateCcw: () => pdf.rotateCurrentPage(clockwise: false),
                onRotateCw: () => pdf.rotateCurrentPage(clockwise: true),
                onSplit: _onSplit,
                onMerge: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MergeScreen())),
                onConvert: _onConvert,
              ),

              // 메인 콘텐츠: 사이드바 + 뷰어
              Expanded(
                child: Row(
                  children: [
                    // 사이드바 (240px)
                    Sidebar(
                      pageCount: pdf.pageCount,
                      selectedPage: pdf.currentPage,
                      onPageSelected: pdf.setPage,
                    ),

                    // 뷰어 영역
                    Expanded(
                      child: Column(
                        children: [
                          // 뷰어 서브 툴바 (36px)
                          ViewerToolbar(
                            currentPage: pdf.currentPage,
                            totalPages: pdf.pageCount,
                            zoom: _displayZoom,
                            onZoomIn: _zoomIn,
                            onZoomOut: _zoomOut,
                            onFitWidth: () => _setZoom(100),
                            onPrev: pdf.prevPage,
                            onNext: pdf.nextPage,
                          ),

                          // PDF 뷰어
                          Expanded(
                            child: pdf.pdfBytes != null
                                ? PdfViewerWidget(
                                    key: ValueKey(pdf.version),
                                    pdfBytes: pdf.pdfBytes!,
                                    sourceName:
                                        '${pdf.fileName}_v${pdf.version}',
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

              // 하단 상태바 (32px)
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
    );
  }
}
