import '../l10n/strings.dart';
import '../providers/pdf_provider.dart';

/// Abstract interface for edit operations (Undo/Redo pattern)
abstract class EditCommand {
  /// Operation description (e.g., "Rotate page 1 clockwise")
  String get description;

  /// Execute the operation
  void execute(PdfProvider pdf);

  /// Undo the operation
  void undo(PdfProvider pdf);
}

/// Page rotation command
class RotatePageCommand extends EditCommand {
  RotatePageCommand({required this.pageIndex, required this.clockwise});

  final int pageIndex;
  final bool clockwise;

  @override
  String get description => S.current.rotateCommand(pageIndex + 1, clockwise);

  @override
  void execute(PdfProvider pdf) {
    pdf.applyRotation(pageIndex, clockwise: clockwise);
  }

  @override
  void undo(PdfProvider pdf) {
    pdf.applyRotation(pageIndex, clockwise: !clockwise);
  }
}

/// Page reorder command
class ReorderPageCommand extends EditCommand {
  ReorderPageCommand({required this.oldIndex, required this.newIndex});

  final int oldIndex;
  final int newIndex;

  @override
  String get description =>
      S.current.reorderCommand(oldIndex + 1, newIndex + 1);

  @override
  void execute(PdfProvider pdf) {
    pdf.applyReorder(oldIndex, newIndex);
  }

  @override
  void undo(PdfProvider pdf) {
    pdf.applyReorder(newIndex, oldIndex);
  }
}
