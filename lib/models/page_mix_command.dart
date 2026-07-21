import '../l10n/strings.dart';
import '../providers/page_mix_provider.dart';
import 'page_mix.dart';

/// Undo/Redo command interface for page-mix operations.
abstract class PageMixCommand {
  String get description;
  void execute(PageMixProvider provider);
  void undo(PageMixProvider provider);
}

/// Append one or more pages of a source to the end of the output queue.
///
/// Captures the created [PageRef]s on execute so that undo can target the
/// specific instances, and redo can recreate equivalent output.
class AddToOutputCommand extends PageMixCommand {
  AddToOutputCommand({required this.sourceId, required this.pageIndices});

  final String sourceId;
  final List<int> pageIndices;

  final List<PageRef> _createdRefs = [];

  @override
  String get description => S.current.addToOutputCommand(pageIndices.length);

  @override
  void execute(PageMixProvider provider) {
    if (_createdRefs.isEmpty) {
      for (final idx in pageIndices) {
        _createdRefs.add(provider.addPageToOutput(sourceId, idx));
      }
    } else {
      // Redo: 처음 실행 때 만든 PageRef를 그대로 재사용해 instanceId를
      // 보존한다. 새 ref를 발급하면 redo 스택의 후속 커맨드(회전/제거/
      // 이동)가 옛 id를 찾지 못해 조용히 무효화된다.
      for (final ref in _createdRefs) {
        provider.insertIntoOutput(provider.output.length, ref);
      }
    }
  }

  @override
  void undo(PageMixProvider provider) {
    for (final ref in _createdRefs) {
      provider.removeFromOutput(ref.instanceId);
    }
  }
}

/// Remove a single page instance from the output queue.
/// Stores the removed ref + index so undo can restore its original place.
class RemoveFromOutputCommand extends PageMixCommand {
  RemoveFromOutputCommand({required this.instanceId});

  final String instanceId;

  PageRef? _removedRef;
  int _removedIndex = -1;

  @override
  String get description => S.current.removeFromOutputCommand;

  @override
  void execute(PageMixProvider provider) {
    final r = provider.removeFromOutput(instanceId);
    if (r != null) {
      _removedRef = r.ref;
      _removedIndex = r.index;
    }
  }

  @override
  void undo(PageMixProvider provider) {
    final ref = _removedRef;
    if (ref == null || _removedIndex < 0) return;
    provider.insertIntoOutput(_removedIndex, ref);
  }
}

/// Empty the entire output queue. Undo restores the previous contents
/// (same [PageRef] instances, so ids stay valid for older commands).
class ClearOutputCommand extends PageMixCommand {
  List<PageRef> _cleared = const [];

  @override
  String get description => S.current.clearOutput;

  @override
  void execute(PageMixProvider provider) {
    _cleared = List.of(provider.output);
    provider.clearOutput();
  }

  @override
  void undo(PageMixProvider provider) {
    provider.setOutput(_cleared);
  }
}

/// Rotate a single output page instance 90° (clockwise or counterclockwise).
/// Inverse is simply a rotation the other way.
class RotateOutputCommand extends PageMixCommand {
  RotateOutputCommand({required this.instanceId, required this.clockwise});

  final String instanceId;
  final bool clockwise;

  @override
  String get description => S.current.rotateOutputCommand(clockwise);

  @override
  void execute(PageMixProvider provider) {
    provider.rotateOutput(instanceId, clockwise: clockwise);
  }

  @override
  void undo(PageMixProvider provider) {
    provider.rotateOutput(instanceId, clockwise: !clockwise);
  }
}

/// Move an output page from [oldIndex] to [newIndex].
/// Undo removes the moved instance by id and re-inserts it at [oldIndex].
class ReorderOutputCommand extends PageMixCommand {
  ReorderOutputCommand({
    required this.instanceId,
    required this.oldIndex,
    required this.newIndex,
  });

  final String instanceId;
  final int oldIndex;
  final int newIndex;

  @override
  String get description => S.current.reorderCommand(oldIndex + 1, newIndex + 1);

  @override
  void execute(PageMixProvider provider) {
    provider.reorderOutput(oldIndex, newIndex);
  }

  @override
  void undo(PageMixProvider provider) {
    final r = provider.removeFromOutput(instanceId);
    if (r != null) {
      provider.insertIntoOutput(oldIndex, r.ref);
    }
  }
}
