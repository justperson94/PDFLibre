import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/utils/file_naming.dart';

void main() {
  group('uniqueOutputPath', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_naming_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('파일이 없으면 경로를 그대로 반환한다', () {
      final path = '${tempDir.path}/doc.pdf';
      expect(uniqueOutputPath(path), path);
    });

    test('파일이 있으면 " (2)"를 붙인다', () {
      final path = '${tempDir.path}/doc.pdf';
      File(path).writeAsStringSync('x');
      expect(uniqueOutputPath(path), '${tempDir.path}/doc (2).pdf');
    });

    test('연속 충돌 시 번호가 증가한다', () {
      final path = '${tempDir.path}/doc.pdf';
      File(path).writeAsStringSync('x');
      File('${tempDir.path}/doc (2).pdf').writeAsStringSync('x');
      File('${tempDir.path}/doc (3).pdf').writeAsStringSync('x');
      expect(uniqueOutputPath(path), '${tempDir.path}/doc (4).pdf');
    });

    test('확장자가 없는 파일도 처리한다', () {
      final path = '${tempDir.path}/README';
      File(path).writeAsStringSync('x');
      expect(uniqueOutputPath(path), '${tempDir.path}/README (2)');
    });

    test('디렉토리명에 점이 있어도 확장자를 올바르게 찾는다', () {
      final dotted = Directory('${tempDir.path}/v1.2')..createSync();
      final path = '${dotted.path}/doc';
      File(path).writeAsStringSync('x');
      // 파일명에 점이 없으므로 디렉토리의 점을 확장자로 오인하면 안 된다.
      expect(uniqueOutputPath(path), '${dotted.path}/doc (2)');
    });

    test('이미지 확장자 유지', () {
      final path = '${tempDir.path}/page_1.png';
      File(path).writeAsStringSync('x');
      expect(uniqueOutputPath(path), '${tempDir.path}/page_1 (2).png');
    });
  });
}
