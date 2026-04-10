import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// PDF rendering viewer widget (based on pdfrx)
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
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.surfaceSecondary,
      child: PdfViewer.data(
        widget.pdfBytes,
        sourceName: widget.sourceName,
        controller: widget.controller,
        params: PdfViewerParams(
          margin: AppTheme.spacingXl,
          backgroundColor: c.surfaceSecondary,
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
}
