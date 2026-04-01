import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/services/pdf_service.dart';

void main() {
  group('PdfService.parsePageRange', () {
    test('단일 페이지 파싱', () {
      expect(PdfService.parsePageRange('3', 10), [2]);
    });

    test('여러 단일 페이지 파싱', () {
      expect(PdfService.parsePageRange('1, 3, 5', 10), [0, 2, 4]);
    });

    test('범위 파싱', () {
      expect(PdfService.parsePageRange('1-3', 10), [0, 1, 2]);
    });

    test('복합 범위 파싱', () {
      expect(
        PdfService.parsePageRange('1-3, 5, 7-10', 10),
        [0, 1, 2, 4, 6, 7, 8, 9],
      );
    });

    test('중복 제거 및 정렬', () {
      expect(PdfService.parsePageRange('3, 1-3, 2', 10), [0, 1, 2]);
    });

    test('전체 페이지', () {
      expect(PdfService.parsePageRange('1-5', 5), [0, 1, 2, 3, 4]);
    });

    test('마지막 페이지만', () {
      expect(PdfService.parsePageRange('10', 10), [9]);
    });

    test('공백 처리', () {
      expect(PdfService.parsePageRange(' 1 - 3 , 5 ', 10), [0, 1, 2, 4]);
    });

    test('빈 문자열은 빈 리스트 반환', () {
      expect(PdfService.parsePageRange('', 10), isEmpty);
    });

    test('범위 초과 시 RangeError', () {
      expect(
        () => PdfService.parsePageRange('11', 10),
        throwsA(isA<RangeError>()),
      );
    });

    test('0 이하 페이지 시 RangeError', () {
      expect(
        () => PdfService.parsePageRange('0', 10),
        throwsA(isA<RangeError>()),
      );
    });

    test('역순 범위 시 RangeError', () {
      expect(
        () => PdfService.parsePageRange('5-3', 10),
        throwsA(isA<RangeError>()),
      );
    });

    test('잘못된 형식 시 FormatException', () {
      expect(
        () => PdfService.parsePageRange('1-2-3', 10),
        throwsA(isA<FormatException>()),
      );
    });

    test('숫자가 아닌 입력 시 FormatException', () {
      expect(
        () => PdfService.parsePageRange('abc', 10),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FileService.formatFileSize', () {
    // formatFileSize는 FileService에 있지만, 순수 함수이므로 여기서 테스트
    test('바이트 단위', () {
      expect(_formatFileSize(500), '500 B');
    });

    test('KB 단위', () {
      expect(_formatFileSize(2048), '2 KB');
    });

    test('MB 단위', () {
      expect(_formatFileSize(1536 * 1024), '1.5 MB');
    });
  });
}

// FileService.formatFileSize를 직접 테스트하기 위한 복사
// (FileService는 file_picker에 의존하므로 유닛 테스트에서 직접 import하기 어려움)
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
