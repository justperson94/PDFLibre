import 'dart:convert';
import 'dart:typed_data';

/// 테스트용 최소 PDF 바이트를 생성한다.
///
/// 각 페이지는 내용 없는 빈 페이지지만 MediaBox 크기를 다르게 줄 수 있어,
/// 병합 결과에서 "몇 번째 원본의 몇 페이지였는지"를 페이지 크기로 식별할 수
/// 있다 (E2E 순서/회전 검증용).
Uint8List buildTestPdf(List<({double width, double height})> pages) {
  final n = pages.length;
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [${List.generate(n, (i) => '${3 + i} 0 R').join(' ')}] /Count $n >>',
    for (final p in pages)
      '<< /Type /Page /Parent 2 0 R /Resources << >> '
          '/MediaBox [0 0 ${p.width.toStringAsFixed(0)} ${p.height.toStringAsFixed(0)}] >>',
  ];

  final buf = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buf.length);
    buf.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xrefOffset = buf.length;
  buf
    ..write('xref\n0 ${objects.length + 1}\n')
    ..write('0000000000 65535 f \n');
  for (final off in offsets) {
    buf.write('${off.toString().padLeft(10, '0')} 00000 n \n');
  }
  buf.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xrefOffset\n%%EOF\n',
  );
  return Uint8List.fromList(ascii.encode(buf.toString()));
}

/// [count]장짜리 테스트 PDF. 페이지 폭이 `baseWidth + 페이지 인덱스`라
/// 크기로 원본 페이지를 식별할 수 있다.
Uint8List buildSequentialPdf(int count, {double baseWidth = 100}) {
  return buildTestPdf([
    for (var i = 0; i < count; i++) (width: baseWidth + i, height: 200),
  ]);
}
