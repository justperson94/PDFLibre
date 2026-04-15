import 'page_mix.dart';
import '../providers/page_mix_provider.dart';

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
  String get description =>
      '출력에 ${pageIndices.length}페이지 추가';

  @override
  void execute(PageMixProvider provider) {
    _createdRefs.clear();
    for (final idx in pageIndices) {
      _createdRefs.add(provider.addPageToOutput(sourceId, idx));
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
  String get description => '출력에서 페이지 제거';

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

/// Rotate a single output page instance 90° (clockwise or counterclockwise).
/// Inverse is simply a rotation the other way.
class RotateOutputCommand extends PageMixCommand {
  RotateOutputCommand({required this.instanceId, required this.clockwise});

  final String instanceId;
  final bool clockwise;

  @override
  String get description =>
      clockwise ? '출력 페이지 시계방향 회전' : '출력 페이지 반시계방향 회전';

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
  String get description => '페이지 ${oldIndex + 1} → ${newIndex + 1}번째로 이동';

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
