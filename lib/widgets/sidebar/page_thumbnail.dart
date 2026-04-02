import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// Sidebar page thumbnail (actual PDF rendering + rotation metadata)
class PageThumbnail extends StatefulWidget {
  const PageThumbnail({
    super.key,
    required this.page,
    required this.pageNumber,
    required this.selected,
    required this.onTap,
    this.rotation = 0,
    this.dragIndex,
  });

  final PdfPage page;
  final int pageNumber;
  final bool selected;
  final VoidCallback onTap;

  /// Rotation angle (0, 90, 180, 270)
  final int rotation;

  /// Index for drag handle (null disables dragging)
  final int? dragIndex;

  @override
  State<PageThumbnail> createState() => _PageThumbnailState();
}

class _PageThumbnailState extends State<PageThumbnail> {
  ui.Image? _thumbnail;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _renderThumbnail();
  }

  @override
  void didUpdateWidget(PageThumbnail oldWidget) {
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
      // Render at higher resolution for better clarity
      const thumbWidth = 160.0;
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
    final rotation = widget.rotation % 360;

    // Fixed size container (consistent row height regardless of rotation)
    const fixedSize = 64.0;

    Widget imageWidget = _thumbnail != null
        ? RawImage(image: _thumbnail, fit: BoxFit.contain)
        : const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.foregroundMuted,
              ),
            ),
          );

    // Apply RotatedBox if rotated (layout size changes accordingly)
    if (rotation != 0 && _thumbnail != null) {
      imageWidget = RotatedBox(
        quarterTurns: rotation ~/ 90,
        child: imageWidget,
      );
    }

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        height: fixedSize + AppTheme.spacingSm * 2,
        decoration: BoxDecoration(
          color: widget.selected
              ? AppTheme.accentPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: widget.selected
                  ? AppTheme.accentPrimary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(
          children: [
            // Drag handle
            if (widget.dragIndex != null)
              ReorderableDragStartListener(
                index: widget.dragIndex!,
                child: const Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingXs),
                  child: Icon(
                    LucideIcons.gripVertical,
                    size: 14,
                    color: AppTheme.foregroundMuted,
                  ),
                ),
              ),
            // Fixed size thumbnail area -- image centered inside
            SizedBox(
              width: fixedSize,
              height: fixedSize,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(AppTheme.roundedSm),
                    border: Border.all(
                      color: widget.selected
                          ? AppTheme.accentPrimary
                          : AppTheme.borderSubtle,
                      width: widget.selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageWidget,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                '${widget.pageNumber} 페이지',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.selected
                      ? AppTheme.accentPrimary
                      : AppTheme.foregroundSecondary,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
