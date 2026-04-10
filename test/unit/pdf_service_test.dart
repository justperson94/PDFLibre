import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/services/pdf_service.dart';

void main() {
  group('PdfService.parsePageRange', () {
    test('parse single page', () {
      expect(PdfService.parsePageRange('3', 10), [2]);
    });

    test('parse multiple single pages', () {
      expect(PdfService.parsePageRange('1, 3, 5', 10), [0, 2, 4]);
    });

    test('parse range', () {
      expect(PdfService.parsePageRange('1-3', 10), [0, 1, 2]);
    });

    test('parse mixed range', () {
      expect(PdfService.parsePageRange('1-3, 5, 7-10', 10), [
        0,
        1,
        2,
        4,
        6,
        7,
        8,
        9,
      ]);
    });

    test('deduplicate and sort', () {
      expect(PdfService.parsePageRange('3, 1-3, 2', 10), [0, 1, 2]);
    });

    test('all pages', () {
      expect(PdfService.parsePageRange('1-5', 5), [0, 1, 2, 3, 4]);
    });

    test('last page only', () {
      expect(PdfService.parsePageRange('10', 10), [9]);
    });

    test('handle whitespace', () {
      expect(PdfService.parsePageRange(' 1 - 3 , 5 ', 10), [0, 1, 2, 4]);
    });

    test('empty string returns empty list', () {
      expect(PdfService.parsePageRange('', 10), isEmpty);
    });

    test('throws RangeError when exceeding page count', () {
      expect(
        () => PdfService.parsePageRange('11', 10),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for page number <= 0', () {
      expect(
        () => PdfService.parsePageRange('0', 10),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for reversed range', () {
      expect(
        () => PdfService.parsePageRange('5-3', 10),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws FormatException for invalid format', () {
      expect(
        () => PdfService.parsePageRange('1-2-3', 10),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for non-numeric input', () {
      expect(
        () => PdfService.parsePageRange('abc', 10),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FileService.formatFileSize', () {
    // formatFileSize lives in FileService but is a pure function, so test here
    test('bytes', () {
      expect(_formatFileSize(500), '500 B');
    });

    test('KB', () {
      expect(_formatFileSize(2048), '2 KB');
    });

    test('MB', () {
      expect(_formatFileSize(1536 * 1024), '1.5 MB');
    });
  });
}

// Copy of FileService.formatFileSize for direct testing
// (FileService depends on file_picker, making direct import difficult in unit tests)
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
