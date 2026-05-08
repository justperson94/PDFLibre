import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// Tray thumbnail tile for the 페이지 혼합 source tray.
///
/// 84×116 rectangle, 4px corner radius, source-color selection ring (2px)
/// when [selected]; otherwise subtle border.
class PageThumbnailTile extends StatefulWidget {
  const PageThumbnailTile({
    super.key,
    required this.page,
    required this.selected,
    required this.sourceColor,
    required this.onTap,
    this.width = 84,
    this.height = 116,
  });

  final PdfPage page;
  final bool selected;
  final Color sourceColor;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  State<PageThumbnailTile> createState() => _PageThumbnailTileState();
}

class _PageThumbnailTileState extends State<PageThumbnailTile> {
  ui.Image? _thumbnail;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _renderThumbnail();
  }

  @override
  void didUpdateWidget(PageThumbnailTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _thumbnail?.dispose();
      _thumbnail = null;
      _renderThumbnail();
    }
  }

  @override
  void dispose() {
    _thumbnail?.dispose();
    super.dispose();
  }

  Future<void> _renderThumbnail() async {
    if (_loading) return;
    _loading = true;
    try {
      final renderWidth = widget.width * 2; // 2x for sharpness
      final scale = renderWidth / widget.page.width;
      final renderHeight = widget.page.height * scale;

      final pdfImage = await widget.page.render(
        fullWidth: renderWidth,
        fullHeight: renderHeight,
      );
      if (pdfImage == null || !mounted) {
        pdfImage?.dispose();
        return;
      }
      final image = await pdfImage.createImage();
      pdfImage.dispose();

      if (mounted) {
        setState(() => _thumbnail = image);
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
    final colors = context.colors;
    final borderColor =
        widget.selected ? widget.sourceColor : colors.borderSubtle;
    final borderWidth = widget.selected ? 2.0 : 1.0;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppTheme.roundedSm),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppTheme.roundedSm),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: _thumbnail != null
            ? RawImage(image: _thumbnail, fit: BoxFit.contain)
            : Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colors.foregroundMuted,
                  ),
                ),
              ),
      ),
    );
  }
}
