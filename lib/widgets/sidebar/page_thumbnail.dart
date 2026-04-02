import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// 사이드바 페이지 썸네일 (실제 PDF 렌더링 + 회전 메타데이터 반영)
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

  /// 회전 각도 (0, 90, 180, 270)
  final int rotation;

  /// 드래그 핸들용 인덱스 (null이면 드래그 비활성)
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
    final rotation = widget.rotation % 360;

    // 고정 크기 컨테이너 (회전과 무관하게 행 높이 일정)
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

    // 회전이 있으면 RotatedBox 적용 (레이아웃 크기도 함께 변경)
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
            // 드래그 핸들
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
            // 고정 크기 썸네일 영역 — 내부에서 이미지를 중앙 정렬
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
