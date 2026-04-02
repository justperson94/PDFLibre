import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import '../services/file_service.dart';

/// PDF 문서 상태 관리 프로바이더
class PdfProvider extends ChangeNotifier {
  PdfDocument? _document;
  Uint8List? _pdfBytes;
  Uint8List? _originalPdfBytes;
  int _version = 0;
  int _viewerVersion = 0;
  String _originalFilePath = '';
  String _fileName = '';
  String _fileSize = '';
  int _currentPage = 1;
  bool _isGridView = false;
  bool _isLoading = false;
  String? _error;

  /// 페이지별 회전 각도 (원본 페이지 인덱스 → 0, 90, 180, 270)
  final Map<int, int> _rotations = {};

  /// 페이지 표시 순서 (표시 인덱스 → 원본 페이지 인덱스)
  List<int> _pageOrder = [];

  Timer? _encodeTimer;

  // === Getters ===
  PdfDocument? get document => _document;
  Uint8List? get pdfBytes => _pdfBytes;
  int get version => _version;
  int get viewerVersion => _viewerVersion;
  bool get hasDocument => _document != null;
  int get pageCount => _document?.pages.length ?? 0;
  int get currentPage => _currentPage;
  bool get isGridView => _isGridView;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fileName => _fileName;
  String get fileSize => _fileSize;
  String get originalFilePath => _originalFilePath;
  Map<int, int> get rotations => Map.unmodifiable(_rotations);
  List<int> get pageOrder => List.unmodifiable(_pageOrder);

  /// 표시 인덱스에 해당하는 원본 페이지 인덱스
  int getOriginalPageIndex(int displayIndex) => _pageOrder[displayIndex];

  /// 표시 인덱스 기준 회전 각도 반환
  int getPageRotation(int displayIndex) =>
      _rotations[_pageOrder[displayIndex]] ?? 0;

  /// PDF 파일 로드
  Future<bool> loadPdf(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _encodeTimer?.cancel();
      _document?.dispose();
      _document = null;

      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('파일을 찾을 수 없습니다', filePath);
      }

      // Dart가 파일을 바이트로 읽고, pdfium에 바이트를 직접 전달 (macOS 샌드박스 우회)
      final bytes = await file.readAsBytes();
      _document = await PdfDocument.openData(bytes, sourceName: filePath);
      _originalPdfBytes = bytes;
      _pdfBytes = bytes;
      _version++;
      _viewerVersion++;
      _originalFilePath = filePath;
      _fileName = Uri.file(filePath).pathSegments.last;
      _fileSize = FileService.formatFileSize(bytes.length);
      _currentPage = 1;
      _rotations.clear();
      _pageOrder = List.generate(_document!.pages.length, (i) => i);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _document = null;
      _pdfBytes = null;
      _originalPdfBytes = null;
      _originalFilePath = '';
      _fileName = '';
      _fileSize = '';
      _rotations.clear();
      _pageOrder = [];
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 페이지 회전 적용 (커맨드 시스템용, 원본 페이지 인덱스 기준)
  void applyRotation(int originalPageIndex, {required bool clockwise}) {
    if (_document == null) return;

    final current = _rotations[originalPageIndex] ?? 0;
    final delta = clockwise ? 90 : -90;
    final newRotation = ((current + delta) % 360 + 360) % 360;

    if (newRotation == 0) {
      _rotations.remove(originalPageIndex);
    } else {
      _rotations[originalPageIndex] = newRotation;
    }

    _version++;
    notifyListeners();
    _scheduleRebuild();
  }

  /// 페이지 순서 변경 적용 (커맨드 시스템용, 표시 인덱스 기준)
  void applyReorder(int oldDisplayIndex, int newDisplayIndex) {
    if (_document == null) return;
    if (oldDisplayIndex == newDisplayIndex) return;
    if (oldDisplayIndex < 0 || oldDisplayIndex >= _pageOrder.length) return;
    if (newDisplayIndex < 0 || newDisplayIndex >= _pageOrder.length) return;

    final item = _pageOrder.removeAt(oldDisplayIndex);
    _pageOrder.insert(newDisplayIndex, item);

    // 현재 페이지가 이동한 페이지면 따라감
    if (_currentPage == oldDisplayIndex + 1) {
      _currentPage = newDisplayIndex + 1;
    }

    _version++;
    notifyListeners();
    _scheduleRebuild();
  }

  /// 뷰어 바이트 재생성 디바운스 스케줄
  void _scheduleRebuild() {
    _encodeTimer?.cancel();
    _encodeTimer = Timer(const Duration(milliseconds: 300), _rebuildViewerBytes);
  }

  /// 페이지 순서가 기본 순서인지 확인
  bool get _isDefaultOrder {
    for (var i = 0; i < _pageOrder.length; i++) {
      if (_pageOrder[i] != i) return false;
    }
    return true;
  }

  /// 디바운스된 뷰어 바이트 재생성
  Future<void> _rebuildViewerBytes() async {
    if (_document == null || _originalPdfBytes == null) return;
    final versionAtStart = _version;

    if (_rotations.isEmpty && _isDefaultOrder) {
      if (!identical(_pdfBytes, _originalPdfBytes)) {
        _pdfBytes = _originalPdfBytes;
        _viewerVersion++;
        notifyListeners();
      }
      return;
    }

    try {
      // 원본 문서에서 페이지를 읽어 별도 새 문서에 배치 (splitPages 패턴)
      final sourceDoc = await PdfDocument.openData(
        _originalPdfBytes!,
        sourceName: 'temp_source',
      );
      final targetDoc = await PdfDocument.createNew(sourceName: 'temp_target');

      final newPages = <PdfPage>[];
      for (final origIdx in _pageOrder) {
        var page = sourceDoc.pages[origIdx];
        final turns = ((_rotations[origIdx] ?? 0) % 360) ~/ 90;
        for (var t = 0; t < turns; t++) {
          page = page.rotatedCW90();
        }
        newPages.add(page);
      }
      targetDoc.pages = newPages;
      await targetDoc.assemble();
      final bytes = await targetDoc.encodePdf();
      targetDoc.dispose();
      sourceDoc.dispose();

      if (_version != versionAtStart) return;

      _pdfBytes = bytes;
      _viewerVersion++;
      notifyListeners();
    } catch (e) {
      debugPrint('PDF 뷰어 바이트 재생성 실패: $e');
    }
  }

  /// 문서 닫기
  void closeDocument() {
    _encodeTimer?.cancel();
    _document?.dispose();
    _document = null;
    _pdfBytes = null;
    _originalPdfBytes = null;
    _originalFilePath = '';
    _fileName = '';
    _fileSize = '';
    _currentPage = 1;
    _rotations.clear();
    _pageOrder = [];
    _error = null;
    notifyListeners();
  }

  // === 페이지 탐색 ===
  void setPage(int page) {
    if (page >= 1 && page <= pageCount && page != _currentPage) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void nextPage() => setPage(_currentPage + 1);
  void prevPage() => setPage(_currentPage - 1);

  // === 뷰 모드 ===
  void setGridView(bool isGrid) {
    if (_isGridView != isGrid) {
      _isGridView = isGrid;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _encodeTimer?.cancel();
    _document?.dispose();
    super.dispose();
  }
}
