import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

/// PDF 처리 서비스 (렌더링, 변환, 분할, 병합)
class PdfService {
  /// PDF 페이지를 이미지로 렌더링 (썸네일/미리보기용)
  static Future<PdfImage?> renderPage(PdfPage page, {double dpi = 150}) async {
    final scale = dpi / 72;
    return page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
    );
  }

  /// PDF 페이지를 지정 포맷의 이미지 바이트로 변환
  static Future<Uint8List> convertPageToImageBytes({
    required PdfPage page,
    required String format,
    double dpi = 300,
    int quality = 85,
  }) async {
    final pdfImage = await renderPage(page, dpi: dpi);
    if (pdfImage == null) throw Exception('페이지 렌더링에 실패했습니다');

    final image = pdfImage.createImageNF();
    pdfImage.dispose();

    // 이미지 인코딩을 별도 isolate에서 실행하여 UI 끊김 방지
    return compute(_encodeImageIsolate, _EncodeRequest(
      pixels: image.toUint8List(),
      width: image.width,
      height: image.height,
      format: format,
      quality: quality,
    ));
  }

  /// PDF 페이지들을 이미지 파일로 저장
  static Future<void> convertPagesToImages({
    required PdfDocument document,
    required List<int> pageIndices,
    required String outputDir,
    required String format,
    double dpi = 300,
    int quality = 85,
    void Function(int current, int total)? onProgress,
  }) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final ext = format.toUpperCase() == 'TIFF' ? 'tif' : format.toLowerCase();
    for (var i = 0; i < pageIndices.length; i++) {
      onProgress?.call(i + 1, pageIndices.length);
      // UI가 진행률을 표시할 수 있도록 프레임 양보
      await Future<void>.delayed(Duration.zero);

      final page = document.pages[pageIndices[i]];
      final bytes = await convertPageToImageBytes(
        page: page,
        format: format,
        dpi: dpi,
        quality: quality,
      );

      final fileName = 'page_${pageIndices[i] + 1}.$ext';
      await File('$outputDir/$fileName').writeAsBytes(bytes);
    }
  }

  /// PDF 분할 — 지정된 페이지들을 새 PDF로 추출
  static Future<Uint8List> splitPages({
    required PdfDocument source,
    required List<int> pageIndices,
  }) async {
    final newDoc = await PdfDocument.createNew(sourceName: 'split.pdf');
    try {
      newDoc.pages = pageIndices.map((i) => source.pages[i]).toList();
      return await newDoc.encodePdf();
    } finally {
      newDoc.dispose();
    }
  }

  /// PDF 분할 후 파일로 저장
  static Future<void> splitToFile({
    required PdfDocument source,
    required List<int> pageIndices,
    required String outputPath,
  }) async {
    final bytes = await splitPages(source: source, pageIndices: pageIndices);
    await File(outputPath).writeAsBytes(bytes);
  }

  /// PDF 병합 — 여러 문서의 페이지를 합쳐 새 PDF 생성
  static Future<Uint8List> mergePages({required List<PdfPage> pages}) async {
    final newDoc = await PdfDocument.createNew(sourceName: 'merged.pdf');
    try {
      newDoc.pages = pages;
      return await newDoc.encodePdf();
    } finally {
      newDoc.dispose();
    }
  }

  /// PDF 병합 후 파일로 저장
  static Future<void> mergeToFile({
    required List<PdfPage> pages,
    required String outputPath,
  }) async {
    final bytes = await mergePages(pages: pages);
    await File(outputPath).writeAsBytes(bytes);
  }

  /// 페이지 범위 문자열 파싱 ("1-3, 5, 7-10" → [0, 1, 2, 4, 6, 7, 8, 9])
  static List<int> parsePageRange(String rangeStr, int totalPages) {
    final indices = <int>{};
    final parts = rangeStr.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('-')) {
        final rangeParts = trimmed.split('-');
        if (rangeParts.length != 2) {
          throw FormatException('잘못된 범위 형식: $trimmed');
        }
        final start = int.parse(rangeParts[0].trim());
        final end = int.parse(rangeParts[1].trim());
        if (start < 1 || end > totalPages || start > end) {
          throw RangeError('범위가 올바르지 않습니다: $trimmed (1~$totalPages)');
        }
        for (var i = start; i <= end; i++) {
          indices.add(i - 1); // 0-based
        }
      } else {
        final page = int.parse(trimmed);
        if (page < 1 || page > totalPages) {
          throw RangeError('페이지 번호가 올바르지 않습니다: $page (1~$totalPages)');
        }
        indices.add(page - 1); // 0-based
      }
    }

    final sorted = indices.toList()..sort();
    return sorted;
  }

}

/// isolate 간 전달용 인코딩 요청 데이터
class _EncodeRequest {
  const _EncodeRequest({
    required this.pixels,
    required this.width,
    required this.height,
    required this.format,
    required this.quality,
  });
  final Uint8List pixels;
  final int width;
  final int height;
  final String format;
  final int quality;
}

/// 별도 isolate에서 실행되는 이미지 인코딩 함수
Uint8List _encodeImageIsolate(_EncodeRequest req) {
  final image = img.Image.fromBytes(
    width: req.width,
    height: req.height,
    bytes: req.pixels.buffer,
    numChannels: 4,
  );

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
      throw ArgumentError('지원하지 않는 포맷: ${req.format}');
  }
}
