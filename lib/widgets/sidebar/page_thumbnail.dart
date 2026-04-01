import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// 사이드바 페이지 썸네일 (실제 PDF 렌더링)
class PageThumbnail extends StatefulWidget {
  const PageThumbnail({
    super.key,
    required this.page,
    required this.pageNumber,
    required this.selected,
    required this.onTap,
  });

  final PdfPage page;
  final int pageNumber;
  final bool selected;
  final VoidCallback onTap;

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
      // 2x 해상도로 렌더링하여 선명도 향상
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
      // 렌더링 실패 시 placeholder 유지
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 페이지 비율에 맞게 썸네일 크기 결정
    final isLandscape = widget.page.width > widget.page.height;
    final thumbWidth = isLandscape ? 64.0 : 48.0;
    final thumbHeight = isLandscape ? 48.0 : 64.0;

    return InkWell(
      onTap: widget.onTap,
      child: Container(
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
            // 썸네일 이미지
            Container(
              width: thumbWidth,
              height: thumbHeight,
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
              child: _thumbnail != null
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
                    ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              '${widget.pageNumber} 페이지',
              style: TextStyle(
                fontSize: 13,
                color: widget.selected
                    ? AppTheme.accentPrimary
                    : AppTheme.foregroundSecondary,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
