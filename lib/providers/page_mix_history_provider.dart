import 'package:flutter/foundation.dart';

import '../models/page_mix_command.dart';
import 'page_mix_provider.dart';

/// Undo/Redo history for [PageMixProvider] operations.
///
/// Parallel to [HistoryProvider] (which is PDF-viewer-specific) — keeps the
/// page-mix stack independent so that history does not leak between the
/// 파일 순서 / 페이지 혼합 modes.
class PageMixHistoryProvider extends ChangeNotifier {
  static const _maxHistory = 50;

  final List<PageMixCommand> _undoStack = [];
  final List<PageMixCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get undoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;
  String? get redoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  void execute(PageMixCommand command, PageMixProvider target) {
    command.execute(target);
    _undoStack.add(command);
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  void undo(PageMixProvider target) {
    if (!canUndo) return;
    final command = _undoStack.removeLast();
    command.undo(target);
    _redoStack.add(command);
    notifyListeners();
  }

  void redo(PageMixProvider target) {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    command.execute(target);
    _undoStack.add(command);
    notifyListeners();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
