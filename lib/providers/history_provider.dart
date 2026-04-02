import 'package:flutter/foundation.dart';

import '../models/edit_command.dart';
import 'pdf_provider.dart';

/// Undo/Redo 히스토리 관리
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

  /// 커맨드 실행 + 히스토리에 기록
  void execute(EditCommand command, PdfProvider pdf) {
    command.execute(pdf);
    _undoStack.add(command);
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  /// 마지막 작업 되돌리기
  void undo(PdfProvider pdf) {
    if (!canUndo) return;
    final command = _undoStack.removeLast();
    command.undo(pdf);
    _redoStack.add(command);
    notifyListeners();
  }

  /// 되돌린 작업 다시 실행
  void redo(PdfProvider pdf) {
    if (!canRedo) return;
    final command = _redoStack.removeLast();
    command.execute(pdf);
    _undoStack.add(command);
    notifyListeners();
  }

  /// 히스토리 초기화 (새 문서 로드 시)
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
