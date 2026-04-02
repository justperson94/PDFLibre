import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../dialogs/progress_dialog.dart';

/// PDF processing service (rendering, conversion, splitting, merging)
class PdfService {
  /// Render a PDF page as an image (for thumbnails/previews)
  static Future<PdfImage?> renderPage(PdfPage page, {double dpi = 150}) async {
    final scale = dpi / 72;
    return page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
    );
  }

  /// Convert a PDF page to image bytes in the specified format
  static Future<Uint8List> convertPageToImageBytes({
    required PdfPage page,
    required String format,
    double dpi = 300,
    int quality = 85,
    int rotation = 0,
  }) async {
    final pdfImage = await renderPage(page, dpi: dpi);
    if (pdfImage == null) throw Exception('Failed to render page');

    final image = pdfImage.createImageNF();
    pdfImage.dispose();

    // Run image encoding (+rotation) in a separate isolate to prevent UI jank
    return compute(_encodeImageIsolate, _EncodeRequest(
      pixels: image.toUint8List(),
      width: image.width,
      height: image.height,
      format: format,
      quality: quality,
      rotation: rotation,
    ));
  }

  /// Save PDF pages as image files
  static Future<void> convertPagesToImages({
    required PdfDocument document,
    required List<int> pageIndices,
    Map<int, int> rotations = const {},
    required String outputDir,
    required String format,
    double dpi = 300,
    int quality = 85,
    void Function(int current, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final ext = format.toUpperCase() == 'TIFF' ? 'tif' : format.toLowerCase();
    for (var i = 0; i < pageIndices.length; i++) {
      if (cancelToken?.isCancelled ?? false) return;

      onProgress?.call(i + 1, pageIndices.length);
      // Yield a frame so the UI can display progress
      await Future<void>.delayed(Duration.zero);

      final pageIdx = pageIndices[i];
      final page = document.pages[pageIdx];
      final bytes = await convertPageToImageBytes(
        page: page,
        format: format,
        dpi: dpi,
        quality: quality,
        rotation: rotations[pageIdx] ?? 0,
      );

      if (cancelToken?.isCancelled ?? false) return;

      final fileName = 'page_${pageIndices[i] + 1}.$ext';
      await File('$outputDir/$fileName').writeAsBytes(bytes);
    }
  }

  /// Split PDF -- extract specified pages into a new PDF
  static Future<Uint8List> splitPages({
    required PdfDocument source,
    required List<int> pageIndices,
    Map<int, int> rotations = const {},
  }) async {
    final newDoc = await PdfDocument.createNew(sourceName: 'split.pdf');
    try {
      final pages = <PdfPage>[];
      for (final i in pageIndices) {
        var page = source.pages[i];
        final rot = (rotations[i] ?? 0) % 360;
        final turns = rot ~/ 90;
        for (var t = 0; t < turns; t++) {
          page = page.rotatedCW90();
        }
        pages.add(page);
      }
      newDoc.pages = pages;
      final hasRotation = pageIndices.any((i) => (rotations[i] ?? 0) != 0);
      if (hasRotation) {
        await newDoc.assemble();
      }
      return await newDoc.encodePdf();
    } finally {
      newDoc.dispose();
    }
  }

  /// Split PDF and save to file
  static Future<void> splitToFile({
    required PdfDocument source,
    required List<int> pageIndices,
    Map<int, int> rotations = const {},
    required String outputPath,
  }) async {
    final bytes = await splitPages(
      source: source,
      pageIndices: pageIndices,
      rotations: rotations,
    );
    await File(outputPath).writeAsBytes(bytes);
  }

  /// Merge PDF -- combine pages from multiple documents into a new PDF
  static Future<Uint8List> mergePages({required List<PdfPage> pages}) async {
    final newDoc = await PdfDocument.createNew(sourceName: 'merged.pdf');
    try {
      newDoc.pages = pages;
      return await newDoc.encodePdf();
    } finally {
      newDoc.dispose();
    }
  }

  /// Merge PDF and save to file
  static Future<void> mergeToFile({
    required List<PdfPage> pages,
    required String outputPath,
  }) async {
    final bytes = await mergePages(pages: pages);
    await File(outputPath).writeAsBytes(bytes);
  }

  /// Parse page range string ("1-3, 5, 7-10" -> [0, 1, 2, 4, 6, 7, 8, 9])
  static List<int> parsePageRange(String rangeStr, int totalPages) {
    final indices = <int>{};
    final parts = rangeStr.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('-')) {
        final rangeParts = trimmed.split('-');
        if (rangeParts.length != 2) {
          throw FormatException('Invalid range format: $trimmed');
        }
        final start = int.parse(rangeParts[0].trim());
        final end = int.parse(rangeParts[1].trim());
        if (start < 1 || end > totalPages || start > end) {
          throw RangeError('Invalid range: $trimmed (1~$totalPages)');
        }
        for (var i = start; i <= end; i++) {
          indices.add(i - 1); // 0-based
        }
      } else {
        final page = int.parse(trimmed);
        if (page < 1 || page > totalPages) {
          throw RangeError('Invalid page number: $page (1~$totalPages)');
        }
        indices.add(page - 1); // 0-based
      }
    }

    final sorted = indices.toList()..sort();
    return sorted;
  }

}

/// Encoding request data for passing between isolates
class _EncodeRequest {
  const _EncodeRequest({
    required this.pixels,
    required this.width,
    required this.height,
    required this.format,
    required this.quality,
    this.rotation = 0,
  });
  final Uint8List pixels;
  final int width;
  final int height;
  final String format;
  final int quality;
  final int rotation;
}

/// Image encoding function that runs in a separate isolate (includes rotation)
Uint8List _encodeImageIsolate(_EncodeRequest req) {
  var image = img.Image.fromBytes(
    width: req.width,
    height: req.height,
    bytes: req.pixels.buffer,
    numChannels: 4,
  );

  // Apply image rotation if rotation metadata is present
  final rot = req.rotation % 360;
  if (rot != 0) {
    image = img.copyRotate(image, angle: rot);
  }

  switch (req.format.toUpperCase()) {
    case 'PNG':
      return Uint8List.fromList(img.encodePng(image));
    case 'JPEG':
    case 'JPG':
      return Uint8List.fromList(img.encodeJpg(image, quality: req.quality));
    case 'GIF':
      return Uint8List.fromList(img.encodeGif(image));
    case 'TIFF':
      return Uint8List.fromList(img.encodeTiff(image));
    case 'BMP':
      return Uint8List.fromList(img.encodeBmp(image));
    case 'WEBP':
      return Uint8List.fromList(img.encodePng(image));
    default:
      throw ArgumentError('Unsupported format: ${req.format}');
  }
}
