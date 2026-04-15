import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/models/page_mix.dart';
import 'package:pdflibre/models/page_mix_command.dart';
import 'package:pdflibre/models/pdf_file_info.dart';
import 'package:pdflibre/providers/page_mix_history_provider.dart';
import 'package:pdflibre/providers/page_mix_provider.dart';

SourcePdf _src(String id, int pageCount) {
  return SourcePdf(
    id: id,
    info: PdfFileInfo(
      filePath: id,
      fileName: '$id.pdf',
      fileSize: '1.0 MB',
      pageCount: pageCount,
    ),
    colorTag: const Color(0xFF5A7EB5),
  );
}

void main() {
  late PageMixProvider provider;
  late PageMixHistoryProvider history;

  setUp(() {
    provider = PageMixProvider()
      ..injectSourceForTest(_src('a', 5))
      ..injectSourceForTest(_src('b', 3));
    history = PageMixHistoryProvider();
  });

  group('AddToOutputCommand', () {
    test('adds pages, undo removes them', () {
      final cmd =
          AddToOutputCommand(sourceId: 'a', pageIndices: const [0, 1, 2]);
      history.execute(cmd, provider);
      expect(provider.totalOutputPages, 3);
      history.undo(provider);
      expect(provider.totalOutputPages, 0);
    });

    test('redo re-adds pages', () {
      final cmd =
          AddToOutputCommand(sourceId: 'b', pageIndices: const [0]);
      history.execute(cmd, provider);
      history.undo(provider);
      history.redo(provider);
      expect(provider.totalOutputPages, 1);
      expect(provider.output.first.sourceId, 'b');
    });
  });

  group('RemoveFromOutputCommand', () {
    test('removes the target instance, undo restores it at original index',
        () {
      provider.addPageToOutput('a', 0);
      final ref2 = provider.addPageToOutput('a', 1);
      provider.addPageToOutput('a', 2);

      final cmd = RemoveFromOutputCommand(instanceId: ref2.instanceId);
      history.execute(cmd, provider);
      expect(provider.totalOutputPages, 2);
      expect(
        provider.output.any((r) => r.instanceId == ref2.instanceId),
        false,
      );

      history.undo(provider);
      expect(provider.totalOutputPages, 3);
      expect(provider.output[1].instanceId, ref2.instanceId);
    });
  });

  group('ReorderOutputCommand', () {
    test('moves a ref forward, undo restores original order', () {
      final r0 = provider.addPageToOutput('a', 0);
      provider.addPageToOutput('a', 1);
      provider.addPageToOutput('a', 2);

      final cmd = ReorderOutputCommand(
        instanceId: r0.instanceId,
        oldIndex: 0,
        newIndex: 3,
      );
      history.execute(cmd, provider);
      expect(provider.output.map((r) => r.pageIndex).toList(), [1, 2, 0]);

      history.undo(provider);
      expect(provider.output.map((r) => r.pageIndex).toList(), [0, 1, 2]);
    });

    test('moves a ref backward, undo restores original order', () {
      provider.addPageToOutput('a', 0);
      provider.addPageToOutput('a', 1);
      final r2 = provider.addPageToOutput('a', 2);

      final cmd = ReorderOutputCommand(
        instanceId: r2.instanceId,
        oldIndex: 2,
        newIndex: 0,
      );
      history.execute(cmd, provider);
      expect(provider.output.map((r) => r.pageIndex).toList(), [2, 0, 1]);

      history.undo(provider);
      expect(provider.output.map((r) => r.pageIndex).toList(), [0, 1, 2]);
    });
  });

  group('PageMixHistoryProvider', () {
    test('canUndo / canRedo reflect stack state', () {
      expect(history.canUndo, false);
      expect(history.canRedo, false);

      history.execute(
        AddToOutputCommand(sourceId: 'a', pageIndices: const [0]),
        provider,
      );
      expect(history.canUndo, true);
      expect(history.canRedo, false);

      history.undo(provider);
      expect(history.canUndo, false);
      expect(history.canRedo, true);
    });

    test('executing a new command clears redo stack', () {
      history.execute(
        AddToOutputCommand(sourceId: 'a', pageIndices: const [0]),
        provider,
      );
      history.undo(provider);
      expect(history.canRedo, true);

      history.execute(
        AddToOutputCommand(sourceId: 'a', pageIndices: const [1]),
        provider,
      );
      expect(history.canRedo, false);
    });

    test('clear empties both stacks', () {
      history.execute(
        AddToOutputCommand(sourceId: 'a', pageIndices: const [0]),
        provider,
      );
      history.clear();
      expect(history.canUndo, false);
      expect(history.canRedo, false);
    });
  });
}
