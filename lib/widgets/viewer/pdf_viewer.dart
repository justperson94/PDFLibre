import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// Mouse-wheel scroll multiplier for the PDF body viewer.
///
/// pdfrx's default of 0.2 is tuned for continuous trackpad deltas. On Windows
/// and Linux the OS reports a chunky ~120-unit delta per wheel notch, which
/// at 0.2 produces a tiny 24-logical-pixel step per click — extremely
/// sluggish. Bumping the multiplier on those platforms restores the
/// per-notch step to a comfortable ~70px. macOS trackpad keeps the original
/// continuous feel.
double _pdfWheelMultiplier() {
  if (kIsWeb) return 0.6;
  if (Platform.isWindows || Platform.isLinux) return 0.6;
  return 0.2;
}

/// PDF rendering viewer widget (based on pdfrx)
class PdfViewerWidget extends StatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.pdfBytes,
    required this.sourceName,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    this.passwordProvider,
  });

  final Uint8List pdfBytes;
  final String sourceName;
  final PdfViewerController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  /// Supplies the password when the underlying [PdfViewer.data] reopens the
  /// bytes (it loads its own document instance separately from the provider).
  /// Null for unencrypted PDFs.
  final PdfPasswordProvider? passwordProvider;

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
        passwordProvider: widget.passwordProvider,
        params: PdfViewerParams(
          margin: AppTheme.spacingXl,
          backgroundColor: c.surfaceSecondary,
          pageDropShadow: const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
          enableKeyboardNavigation: false,
          scrollByMouseWheel: _pdfWheelMultiplier(),
        ),
        initialPageNumber: widget.currentPage,
      ),
    );
  }
}
