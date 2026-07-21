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
      final cmd = AddToOutputCommand(
        sourceId: 'a',
        pageIndices: const [0, 1, 2],
      );
      history.execute(cmd, provider);
      expect(provider.totalOutputPages, 3);
      history.undo(provider);
      expect(provider.totalOutputPages, 0);
    });

    test('redo re-adds pages', () {
      final cmd = AddToOutputCommand(sourceId: 'b', pageIndices: const [0]);
      history.execute(cmd, provider);
      history.undo(provider);
      history.redo(provider);
      expect(provider.totalOutputPages, 1);
      expect(provider.output.first.sourceId, 'b');
    });

    test('redo preserves instanceId so later redo commands stay valid', () {
      final cmd = AddToOutputCommand(sourceId: 'a', pageIndices: const [0]);
      history.execute(cmd, provider);
      final originalId = provider.output.single.instanceId;

      // 추가 → 회전 → undo×2 → redo×2 시나리오: redo에서 새 인스턴스 ID가
      // 발급되면 회전 redo가 옛 ID를 찾지 못해 조용히 무효화된다.
      history.execute(
        RotateOutputCommand(instanceId: originalId, clockwise: true),
        provider,
      );
      history.undo(provider); // 회전 취소
      history.undo(provider); // 추가 취소
      expect(provider.totalOutputPages, 0);

      history.redo(provider); // 추가 재실행
      expect(provider.output.single.instanceId, originalId);

      history.redo(provider); // 회전 재실행
      expect(provider.output.single.rotationTurns, 1);
    });
  });

  group('ClearOutputCommand', () {
    test('clears the queue, undo restores contents and order', () {
      final r0 = provider.addPageToOutput('a', 0);
      final r1 = provider.addPageToOutput('b', 1);
      final r2 = provider.addPageToOutput('a', 2);

      history.execute(ClearOutputCommand(), provider);
      expect(provider.totalOutputPages, 0);

      history.undo(provider);
      expect(provider.output.map((r) => r.instanceId).toList(), [
        r0.instanceId,
        r1.instanceId,
        r2.instanceId,
      ]);

      history.redo(provider);
      expect(provider.totalOutputPages, 0);
    });
  });

  group('RemoveFromOutputCommand', () {
    test('removes the target instance, undo restores it at original index', () {
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

  group('RotateOutputCommand', () {
    test('clockwise rotation sets 90°, undo returns to 0°', () {
      final ref = provider.addPageToOutput('a', 0);
      expect(ref.rotationTurns, 0);

      final cmd = RotateOutputCommand(
        instanceId: ref.instanceId,
        clockwise: true,
      );
      history.execute(cmd, provider);
      expect(provider.output.single.rotationTurns, 1);

      history.undo(provider);
      expect(provider.output.single.rotationTurns, 0);
    });

    test('counterclockwise rotation sets 270°, undo returns to 0°', () {
      final ref = provider.addPageToOutput('a', 0);

      final cmd = RotateOutputCommand(
        instanceId: ref.instanceId,
        clockwise: false,
      );
      history.execute(cmd, provider);
      expect(provider.output.single.rotationTurns, 3);

      history.undo(provider);
      expect(provider.output.single.rotationTurns, 0);
    });

    test('four clockwise rotations wrap back to 0°', () {
      final ref = provider.addPageToOutput('a', 0);
      for (var i = 0; i < 4; i++) {
        history.execute(
          RotateOutputCommand(instanceId: ref.instanceId, clockwise: true),
          provider,
        );
      }
      expect(provider.output.single.rotationTurns, 0);
    });

    test('only affects the targeted instance', () {
      final r0 = provider.addPageToOutput('a', 0);
      final r1 = provider.addPageToOutput('a', 1);

      history.execute(
        RotateOutputCommand(instanceId: r0.instanceId, clockwise: true),
        provider,
      );
      expect(provider.output.first.rotationTurns, 1);
      expect(
        provider.output
            .firstWhere((r) => r.instanceId == r1.instanceId)
            .rotationTurns,
        0,
      );
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
