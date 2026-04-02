import '../providers/pdf_provider.dart';

/// 편집 작업 추상 인터페이스 (Undo/Redo 패턴)
abstract class EditCommand {
  /// 작업 설명 (예: "1페이지 시계방향 회전")
  String get description;

  /// 작업 실행
  void execute(PdfProvider pdf);

  /// 작업 되돌리기
  void undo(PdfProvider pdf);
}

/// 페이지 회전 커맨드
class RotatePageCommand extends EditCommand {
  RotatePageCommand({required this.pageIndex, required this.clockwise});

  final int pageIndex;
  final bool clockwise;

  @override
  String get description =>
      '${pageIndex + 1}페이지 ${clockwise ? "시계방향" : "반시계방향"} 회전';

  @override
  void execute(PdfProvider pdf) {
    pdf.applyRotation(pageIndex, clockwise: clockwise);
  }

  @override
  void undo(PdfProvider pdf) {
    pdf.applyRotation(pageIndex, clockwise: !clockwise);
  }
}

/// 페이지 순서 변경 커맨드
class ReorderPageCommand extends EditCommand {
  ReorderPageCommand({required this.oldIndex, required this.newIndex});

  final int oldIndex;
  final int newIndex;

  @override
  String get description => '${oldIndex + 1}페이지 → ${newIndex + 1}번째로 이동';

  @override
  void execute(PdfProvider pdf) {
    pdf.applyReorder(oldIndex, newIndex);
  }

  @override
  void undo(PdfProvider pdf) {
    pdf.applyReorder(newIndex, oldIndex);
  }
}
