import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// 실제 PDF 렌더링 뷰어 (pdfrx 기반)
class PdfViewerWidget extends StatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.filePath,
    required this.currentPage,
    required this.onPageChanged,
  });

  final String filePath;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  final _controller = PdfViewerController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onViewerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onViewerChanged);
    super.dispose();
  }

  void _onViewerChanged() {
    if (_syncing || !_controller.isReady) return;
    final viewerPage = _controller.pageNumber;
    if (viewerPage != null && viewerPage != widget.currentPage) {
      widget.onPageChanged(viewerPage);
    }
  }

  @override
  void didUpdateWidget(PdfViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provider에서 페이지 변경 시 뷰어도 동기화
    if (oldWidget.currentPage != widget.currentPage && _controller.isReady) {
      _syncing = true;
      _controller
          .goToPage(pageNumber: widget.currentPage)
          .then((_) => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePath.isEmpty) {
      return _buildPlaceholder();
    }

    return Container(
      color: AppTheme.surfaceSecondary,
      child: PdfViewer.file(
        widget.filePath,
        controller: _controller,
        params: PdfViewerParams(
          margin: AppTheme.spacingXl,
          backgroundColor: AppTheme.surfaceSecondary,
          pageDropShadow: const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
          enableKeyboardNavigation: false,
        ),
        initialPageNumber: widget.currentPage,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceSecondary,
      child: const Center(
        child: Text(
          'PDF를 불러오는 중...',
          style: TextStyle(color: AppTheme.foregroundMuted, fontSize: 14),
        ),
      ),
    );
  }
}
