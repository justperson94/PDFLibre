import 'package:flutter/material.dart';

import 'pdf_file_info.dart';

/// Palette of distinguishable source tag colors used to visually identify
/// pages by their source PDF in the page-mix output canvas.
///
/// Colors are chosen for contrast against neutral surfaces in both light
/// and dark themes, and rotate modulo the palette size as more sources
/// are added.
class SourceColorPalette {
  const SourceColorPalette._();

  static const List<Color> colors = [
    Color(0xFF5A7EB5), // blue
    Color(0xFFEE6B5B), // coral
    Color(0xFF4A9D7C), // green
    Color(0xFF8B6FBF), // purple
    Color(0xFFE89F4A), // orange
    Color(0xFF4A9CAE), // teal
    Color(0xFFCF7B99), // pink
    Color(0xFF7A8C52), // olive
  ];

  static Color forIndex(int index) => colors[index % colors.length];
}

/// A source PDF loaded into the page-mix tray.
///
/// Identified by [id] (typically derived from the absolute file path) and
/// carries a visual [colorTag] for identifying its pages inside the output
/// canvas.
@immutable
class SourcePdf {
  const SourcePdf({
    required this.id,
    required this.info,
    required this.colorTag,
  });

  final String id;
  final PdfFileInfo info;
  final Color colorTag;

  SourcePdf copyWith({String? id, PdfFileInfo? info, Color? colorTag}) {
    return SourcePdf(
      id: id ?? this.id,
      info: info ?? this.info,
      colorTag: colorTag ?? this.colorTag,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourcePdf &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          colorTag == other.colorTag &&
          info.filePath == other.info.filePath;

  @override
  int get hashCode => Object.hash(id, info.filePath, colorTag);
}

/// A single page instance in the page-mix output queue.
///
/// Each instance is independent: the same source page may appear multiple
/// times in the output, and [rotationTurns] applies per-instance only.
@immutable
class PageRef {
  const PageRef({
    required this.instanceId,
    required this.sourceId,
    required this.pageIndex,
    this.rotationTurns = 0,
  });

  final String instanceId;
  final String sourceId;
  final int pageIndex;

  /// Quarter turns clockwise, normalized to 0..3.
  final int rotationTurns;

  int get rotationDegrees => (rotationTurns % 4) * 90;

  PageRef copyWith({
    String? instanceId,
    String? sourceId,
    int? pageIndex,
    int? rotationTurns,
  }) {
    return PageRef(
      instanceId: instanceId ?? this.instanceId,
      sourceId: sourceId ?? this.sourceId,
      pageIndex: pageIndex ?? this.pageIndex,
      rotationTurns: rotationTurns ?? this.rotationTurns,
    );
  }

  PageRef rotatedClockwise() =>
      copyWith(rotationTurns: (rotationTurns + 1) % 4);

  PageRef rotatedCounterClockwise() =>
      copyWith(rotationTurns: (rotationTurns + 3) % 4);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRef &&
          runtimeType == other.runtimeType &&
          instanceId == other.instanceId &&
          sourceId == other.sourceId &&
          pageIndex == other.pageIndex &&
          rotationTurns == other.rotationTurns;

  @override
  int get hashCode =>
      Object.hash(instanceId, sourceId, pageIndex, rotationTurns);
}
