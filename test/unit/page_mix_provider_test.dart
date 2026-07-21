import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/models/page_mix.dart';
import 'package:pdflibre/models/pdf_file_info.dart';
import 'package:pdflibre/providers/page_mix_provider.dart';

SourcePdf _source(String id, int pageCount, Color color) {
  return SourcePdf(
    id: id,
    info: PdfFileInfo(
      filePath: id,
      fileName: '$id.pdf',
      fileSize: '1.0 MB',
      pageCount: pageCount,
    ),
    colorTag: color,
  );
}

void main() {
  group('PageMixProvider selection', () {
    late PageMixProvider provider;

    setUp(() {
      provider = PageMixProvider()
        ..injectSourceForTest(_source('a', 10, const Color(0xFF5A7EB5)));
    });

    test('toggle selection adds and removes pages', () {
      expect(provider.isSelected('a', 0), false);
      provider.togglePageSelection('a', 0);
      expect(provider.isSelected('a', 0), true);
      provider.togglePageSelection('a', 0);
      expect(provider.isSelected('a', 0), false);
    });

    test('selectAllPages selects every page', () {
      provider.selectAllPages('a');
      expect(provider.selectionFor('a').length, 10);
    });

    test('clearSelection empties the selection', () {
      provider.selectAllPages('a');
      provider.clearSelection('a');
      expect(provider.selectionFor('a'), isEmpty);
    });

    test('selectRange replaces selection with parsed indices', () {
      provider.selectRange('a', '1-3, 5');
      expect(provider.selectionFor('a'), {0, 1, 2, 4});
    });

    test('selectRange throws on invalid input', () {
      expect(() => provider.selectRange('a', 'abc'), throwsFormatException);
    });

    test(
      'selectOnlyPage replaces selection with a single page and anchors',
      () {
        provider.togglePageSelection('a', 1);
        provider.togglePageSelection('a', 3);
        provider.selectOnlyPage('a', 7);
        expect(provider.selectionFor('a'), {7});
        expect(provider.selectionAnchor('a'), 7);
      },
    );

    test('togglePageSelection updates the anchor to the toggled page', () {
      provider.togglePageSelection('a', 4);
      expect(provider.selectionAnchor('a'), 4);
      provider.togglePageSelection('a', 8);
      expect(provider.selectionAnchor('a'), 8);
    });

    test('selectRangeFromAnchor uses anchor to fill an inclusive range', () {
      provider.selectOnlyPage('a', 2); // anchor at 2
      provider.selectRangeFromAnchor('a', 6);
      expect(provider.selectionFor('a'), {2, 3, 4, 5, 6});
      // anchor stays put for repeated shift-clicks
      expect(provider.selectionAnchor('a'), 2);
    });

    test('selectRangeFromAnchor handles target before anchor', () {
      provider.selectOnlyPage('a', 6); // anchor at 6
      provider.selectRangeFromAnchor('a', 3);
      expect(provider.selectionFor('a'), {3, 4, 5, 6});
      expect(provider.selectionAnchor('a'), 6);
    });

    test('selectRangeFromAnchor without prior anchor falls back to single', () {
      provider.selectRangeFromAnchor('a', 5);
      expect(provider.selectionFor('a'), {5});
      expect(provider.selectionAnchor('a'), 5);
    });

    test('clearSelection also clears anchor', () {
      provider.selectOnlyPage('a', 3);
      provider.clearSelection('a');
      expect(provider.selectionAnchor('a'), isNull);
    });
  });

  group('PageMixProvider output queue', () {
    late PageMixProvider provider;

    setUp(() {
      provider = PageMixProvider()
        ..injectSourceForTest(_source('a', 10, const Color(0xFF5A7EB5)))
        ..injectSourceForTest(_source('b', 5, const Color(0xFFEE6B5B)));
    });

    test('addPageToOutput appends with unique instance ids', () {
      final r1 = provider.addPageToOutput('a', 0);
      final r2 = provider.addPageToOutput('a', 0);
      expect(provider.output.length, 2);
      expect(r1.instanceId, isNot(r2.instanceId));
    });

    test('addSelectionToOutput uses page-index order', () {
      provider.selectRange('a', '5, 1-2');
      final added = provider.addSelectionToOutput('a');
      expect(added.map((r) => r.pageIndex).toList(), [0, 1, 4]);
      expect(provider.totalOutputPages, 3);
    });

    test('addAllPagesToOutput appends every source page', () {
      provider.addAllPagesToOutput('b');
      expect(provider.output.map((r) => r.pageIndex).toList(), [0, 1, 2, 3, 4]);
    });

    test('addRangeToOutput parses 1-based input', () {
      provider.addRangeToOutput('a', '2-4');
      expect(provider.output.map((r) => r.pageIndex).toList(), [1, 2, 3]);
    });

    test('removeFromOutput removes and returns former index', () {
      provider.addPageToOutput('a', 0);
      final ref2 = provider.addPageToOutput('a', 1);
      provider.addPageToOutput('a', 2);
      final removed = provider.removeFromOutput(ref2.instanceId);
      expect(removed, isNotNull);
      expect(removed!.index, 1);
      expect(removed.ref.pageIndex, 1);
      expect(provider.output.length, 2);
    });

    test('reorderOutput moves ref forward', () {
      provider.addPageToOutput('a', 0);
      provider.addPageToOutput('a', 1);
      provider.addPageToOutput('a', 2);
      provider.reorderOutput(0, 3); // 0 → end
      expect(provider.output.map((r) => r.pageIndex).toList(), [1, 2, 0]);
    });

    test('reorderOutput moves ref backward', () {
      provider.addPageToOutput('a', 0);
      provider.addPageToOutput('a', 1);
      provider.addPageToOutput('a', 2);
      provider.reorderOutput(2, 0); // end → 0
      expect(provider.output.map((r) => r.pageIndex).toList(), [2, 0, 1]);
    });

    test('rotateOutput only affects the targeted instance', () {
      final r1 = provider.addPageToOutput('a', 0);
      final r2 = provider.addPageToOutput('a', 0);
      provider.rotateOutput(r1.instanceId, clockwise: true);
      final updated1 = provider.output.firstWhere(
        (r) => r.instanceId == r1.instanceId,
      );
      final unchanged2 = provider.output.firstWhere(
        (r) => r.instanceId == r2.instanceId,
      );
      expect(updated1.rotationTurns, 1);
      expect(unchanged2.rotationTurns, 0);
    });

    test('removeSource drops output pages from that source', () {
      provider.addPageToOutput('a', 0);
      provider.addPageToOutput('b', 0);
      provider.addPageToOutput('a', 1);
      provider.removeSource('a');
      expect(provider.output.length, 1);
      expect(provider.output.first.sourceId, 'b');
    });

    test('clearOutput empties the queue', () {
      provider.addPageToOutput('a', 0);
      provider.addPageToOutput('a', 1);
      provider.clearOutput();
      expect(provider.output, isEmpty);
    });
  });
}
