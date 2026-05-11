import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../theme/app_theme.dart';

/// Tray thumbnail tile for the 페이지 혼합 source tray.
///
/// 84×116 rectangle, 4px corner radius.
/// - [selected]: source-color ring + tinted wash + check badge (overlay only,
///   the tile itself never resizes).
/// - [outputCount] > 0: a small "in output" indicator at the bottom-left
///   (badge with count) so the user can see at a glance which source pages
///   are already in the output queue, independent of current selection.
class PageThumbnailTile extends StatefulWidget {
  const PageThumbnailTile({
    super.key,
    required this.page,
    required this.selected,
    required this.sourceColor,
    required this.onTap,
    this.outputCount = 0,
    this.width = 84,
    this.height = 116,
  });

  final PdfPage page;
  final bool selected;
  final Color sourceColor;
  final VoidCallback onTap;
  final int outputCount;
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
    final radius = BorderRadius.circular(AppTheme.roundedSm);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base tile — fixed size, subtle 1px border always present so the
            // thumbnail area never shifts when selection toggles.
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: radius,
                border: Border.all(color: colors.borderSubtle, width: 1),
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
            // "Already in output" dim overlay — desaturating wash so the
            // page reads as "used" at a glance. Sits *under* the selection
            // overlay so a currently-selected page still pops with its
            // source color even if also in the output.
            if (widget.outputCount > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
            // Selection overlay — tinted wash + thick colored ring + check
            // badge. Drawn on top so the underlying tile never resizes.
            if (widget.selected) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.sourceColor.withValues(alpha: 0.22),
                      borderRadius: radius,
                      border: Border.all(color: widget.sourceColor, width: 2.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IgnorePointer(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: widget.sourceColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            // "In output" badge — independent of selection. Bottom-left so it
            // doesn't collide with the selection check badge at top-right.
            // Shows count when the page was added more than once (duplicates
            // are allowed via PageRef.instanceId).
            if (widget.outputCount > 0)
              Positioned(
                left: 4,
                bottom: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: colors.foregroundPrimary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: colors.surfacePrimary,
                        ),
                        if (widget.outputCount > 1) ...[
                          const SizedBox(width: 3),
                          Text(
                            '${widget.outputCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.surfacePrimary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
