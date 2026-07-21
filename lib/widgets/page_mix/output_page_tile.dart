import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

/// Output canvas tile for the 페이지 혼합 mode.
///
/// Matches the Pencil `Output p.X` spec: 120×160 vertical card with a
/// 120×130 preview area and a short source/page label. The preview carries
/// a circular global-index badge (top-left) filled with the source color.
/// Per-instance rotation is applied via [rotationTurns].
class OutputPageTile extends StatefulWidget {
  const OutputPageTile({
    super.key,
    required this.page,
    required this.globalIndex,
    required this.sourceColor,
    required this.label,
    this.rotationTurns = 0,
    this.selected = false,
    this.onTap,
    this.onRotateCw,
    this.onRotateCcw,
    this.onRemove,
    this.onMoveLeft,
    this.onMoveRight,
    this.width = 120,
    this.height = 160,
    this.previewHeight = 130,
  });

  final PdfPage page;
  final int globalIndex;
  final Color sourceColor;
  final String label;
  final int rotationTurns;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRotateCw;
  final VoidCallback? onRotateCcw;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final double width;
  final double height;
  final double previewHeight;

  @override
  State<OutputPageTile> createState() => _OutputPageTileState();
}

class _OutputPageTileState extends State<OutputPageTile> {
  ui.Image? _thumbnail;
  bool _loading = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _renderThumbnail();
  }

  @override
  void didUpdateWidget(OutputPageTile oldWidget) {
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
      final renderWidth = widget.width * 2;
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

    Widget preview = _thumbnail != null
        ? RawImage(image: _thumbnail, fit: BoxFit.contain)
        : Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colors.foregroundMuted,
              ),
            ),
          );

    final turns = widget.rotationTurns % 4;
    if (turns != 0 && _thumbnail != null) {
      preview = RotatedBox(quarterTurns: turns, child: preview);
    }

    final borderColor = widget.selected
        ? widget.sourceColor
        : colors.borderSubtle;
    final borderWidth = widget.selected ? 2.0 : 1.0;

    final hasActions =
        widget.onRotateCw != null ||
        widget.onRotateCcw != null ||
        widget.onRemove != null;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
            const _MoveLeftIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
            const _MoveLeftIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
            const _MoveRightIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
            const _MoveRightIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MoveLeftIntent: CallbackAction<_MoveLeftIntent>(
            onInvoke: (_) {
              widget.onMoveLeft?.call();
              return null;
            },
          ),
          _MoveRightIntent: CallbackAction<_MoveRightIntent>(
            onInvoke: (_) {
              widget.onMoveRight?.call();
              return null;
            },
          ),
        },
        child: Focus(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Builder(
              builder: (context) => InkWell(
                onTap: () {
                  Focus.of(context).requestFocus();
                  widget.onTap?.call();
                },
                borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary,
                    borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: widget.width,
                        height: widget.previewHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: colors.surfaceSecondary,
                                alignment: Alignment.center,
                                child: preview,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: _IndexBadge(
                                index: widget.globalIndex,
                                color: widget.sourceColor,
                              ),
                            ),
                            if (hasActions && _hovered)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: _HoverActions(
                                  onRotateCcw: widget.onRotateCcw,
                                  onRotateCw: widget.onRotateCw,
                                  onRemove: widget.onRemove,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXs,
                        ),
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.foregroundSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveLeftIntent extends Intent {
  const _MoveLeftIntent();
}

class _MoveRightIntent extends Intent {
  const _MoveRightIntent();
}

class _HoverActions extends StatelessWidget {
  const _HoverActions({this.onRotateCcw, this.onRotateCw, this.onRemove});

  final VoidCallback? onRotateCcw;
  final VoidCallback? onRotateCw;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.roundedSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRotateCcw != null)
            _HoverIconButton(
              icon: LucideIcons.rotateCcw,
              onPressed: onRotateCcw!,
              tooltip: s.rotateCounterClockwise,
            ),
          if (onRotateCw != null)
            _HoverIconButton(
              icon: LucideIcons.rotateCw,
              onPressed: onRotateCw!,
              tooltip: s.rotateClockwise,
            ),
          if (onRemove != null)
            _HoverIconButton(
              icon: LucideIcons.x,
              onPressed: onRemove!,
              tooltip: s.removeOutputPage,
            ),
        ],
      ),
    );
  }
}

class _HoverIconButton extends StatelessWidget {
  const _HoverIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.roundedSm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$index',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
