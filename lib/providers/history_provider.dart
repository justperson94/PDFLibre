import 'package:flutter/foundation.dart';

import '../models/edit_command.dart';
import 'pdf_provider.dart';

/// Undo/Redo history management
class HistoryProvider extends ChangeNotifier {
  static const _maxHistory = 50;

  final List<EditCommand> _undoStack = [];
  final List<EditCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get undoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;
  String? get redoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  /// Execute command and record in history
  void execute(EditCommand command, PdfProvider pdf) {
    command.execute(pdf);
    _undoStack.add(command);
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  /// Undo the last operation
  void undo(PdfProvider pdf) {
    if (!canUndo) return;
    final command = _undoStack.removeLast();
    command.undo(pdf);
    _redoStack.add(command);
    notifyListeners();
  }

  /// Redo the previously undone operation
  void redo(PdfProvider pdf) {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    command.execute(pdf);
    _undoStack.add(command);
    notifyListeners();
  }

  /// Clear history (when loading a new document)
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
