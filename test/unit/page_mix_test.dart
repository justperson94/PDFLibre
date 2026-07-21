import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/models/page_mix.dart';
import 'package:pdflibre/models/pdf_file_info.dart';

void main() {
  group('SourceColorPalette', () {
    test('has at least 8 distinct colors', () {
      expect(SourceColorPalette.colors.length, greaterThanOrEqualTo(8));
      expect(
        SourceColorPalette.colors.toSet().length,
        SourceColorPalette.colors.length,
        reason: 'palette colors should be distinct',
      );
    });

    test('forIndex wraps modulo palette size', () {
      final size = SourceColorPalette.colors.length;
      expect(SourceColorPalette.forIndex(0), SourceColorPalette.forIndex(size));
      expect(
        SourceColorPalette.forIndex(1),
        SourceColorPalette.forIndex(size + 1),
      );
    });

    test('forIndex returns first color for 0', () {
      expect(SourceColorPalette.forIndex(0), SourceColorPalette.colors.first);
    });
  });

  group('SourcePdf', () {
    final info = const PdfFileInfo(
      filePath: '/tmp/a.pdf',
      fileName: 'a.pdf',
      fileSize: '1.0 MB',
      pageCount: 10,
    );

    test('equality uses id, filePath and colorTag', () {
      final a = SourcePdf(
        id: 's1',
        info: info,
        colorTag: const Color(0xFF112233),
      );
      final b = SourcePdf(
        id: 's1',
        info: info,
        colorTag: const Color(0xFF112233),
      );
      final c = SourcePdf(
        id: 's2',
        info: info,
        colorTag: const Color(0xFF112233),
      );
      expect(a, b);
      expect(a, isNot(c));
    });

    test('copyWith overrides only provided fields', () {
      final base = SourcePdf(
        id: 's1',
        info: info,
        colorTag: const Color(0xFF000000),
      );
      final updated = base.copyWith(colorTag: const Color(0xFFFFFFFF));
      expect(updated.id, 's1');
      expect(updated.info, info);
      expect(updated.colorTag, const Color(0xFFFFFFFF));
    });
  });

  group('PageRef', () {
    test('default rotation is 0', () {
      const ref = PageRef(instanceId: 'p1', sourceId: 's1', pageIndex: 0);
      expect(ref.rotationTurns, 0);
      expect(ref.rotationDegrees, 0);
    });

    test('rotatedClockwise cycles 0 → 90 → 180 → 270 → 0', () {
      PageRef ref = const PageRef(
        instanceId: 'p1',
        sourceId: 's1',
        pageIndex: 0,
      );
      expect(ref.rotationDegrees, 0);
      ref = ref.rotatedClockwise();
      expect(ref.rotationDegrees, 90);
      ref = ref.rotatedClockwise();
      expect(ref.rotationDegrees, 180);
      ref = ref.rotatedClockwise();
      expect(ref.rotationDegrees, 270);
      ref = ref.rotatedClockwise();
      expect(ref.rotationDegrees, 0);
    });

    test('rotatedCounterClockwise cycles 0 → 270 → 180 → 90 → 0', () {
      PageRef ref = const PageRef(
        instanceId: 'p1',
        sourceId: 's1',
        pageIndex: 0,
      );
      ref = ref.rotatedCounterClockwise();
      expect(ref.rotationDegrees, 270);
      ref = ref.rotatedCounterClockwise();
      expect(ref.rotationDegrees, 180);
      ref = ref.rotatedCounterClockwise();
      expect(ref.rotationDegrees, 90);
      ref = ref.rotatedCounterClockwise();
      expect(ref.rotationDegrees, 0);
    });

    test(
      'two refs with same source+page but different instanceId are distinct',
      () {
        const a = PageRef(instanceId: 'p1', sourceId: 's1', pageIndex: 3);
        const b = PageRef(instanceId: 'p2', sourceId: 's1', pageIndex: 3);
        expect(a, isNot(b));
      },
    );

    test('copyWith preserves unchanged fields', () {
      const base = PageRef(
        instanceId: 'p1',
        sourceId: 's1',
        pageIndex: 4,
        rotationTurns: 2,
      );
      final updated = base.copyWith(rotationTurns: 3);
      expect(updated.instanceId, 'p1');
      expect(updated.sourceId, 's1');
      expect(updated.pageIndex, 4);
      expect(updated.rotationTurns, 3);
    });
  });
}
