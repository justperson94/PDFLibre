import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// 실제 PDF 렌더링 뷰어 (pdfrx 기반)
class PdfViewerWidget extends StatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.pdfBytes,
    required this.sourceName,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  final Uint8List pdfBytes;
  final String sourceName;
  final PdfViewerController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  bool _syncing = false;

  /// 문서 리로드 시 복원할 줌 레벨 (null이면 기본 줌 사용)
  double? _zoomToRestore;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onViewerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onViewerChanged);
    super.dispose();
  }

  void _onViewerChanged() {
    if (_syncing || !widget.controller.isReady) return;
    final viewerPage = widget.controller.pageNumber;
    if (viewerPage != null && viewerPage != widget.currentPage) {
      widget.onPageChanged(viewerPage);
    }
  }

  @override
  void didUpdateWidget(PdfViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage &&
        widget.controller.isReady) {
      _syncing = true;
      widget.controller
          .goToPage(pageNumber: widget.currentPage)
          .then((_) => _syncing = false);
    }
    // sourceName이 변경되면 (회전 인코딩 완료) 현재 줌을 저장하여 복원
    if (oldWidget.sourceName != widget.sourceName &&
        widget.controller.isReady) {
      _zoomToRestore = widget.controller.currentZoom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceSecondary,
      child: PdfViewer.data(
        widget.pdfBytes,
        sourceName: widget.sourceName,
        controller: widget.controller,
        params: PdfViewerParams(
          margin: AppTheme.spacingXl,
          backgroundColor: AppTheme.surfaceSecondary,
          pageDropShadow: const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
          enableKeyboardNavigation: false,
          // 문서 리로드 시 이전 줌 레벨 복원
          calculateInitialZoom: _zoomToRestore != null
              ? (document, controller, fitScale, coverScale) {
                  final zoom = _zoomToRestore!;
                  _zoomToRestore = null;
                  return zoom;
                }
              : null,
        ),
        initialPageNumber: widget.currentPage,
      ),
    );
  }
}
