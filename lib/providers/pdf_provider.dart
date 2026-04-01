import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../services/file_service.dart';

/// PDF 문서 상태 관리 프로바이더
class PdfProvider extends ChangeNotifier {
  PdfDocument? _document;
  String? _filePath;
  String _originalFilePath = '';
  String _fileName = '';
  String _fileSize = '';
  int _currentPage = 1;
  double _zoom = 100;
  bool _isGridView = false;
  bool _isLoading = false;
  String? _error;

  // === Getters ===
  PdfDocument? get document => _document;
  bool get hasDocument => _document != null;
  int get pageCount => _document?.pages.length ?? 0;
  int get currentPage => _currentPage;
  double get zoom => _zoom;
  bool get isGridView => _isGridView;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fileName => _fileName;
  String get fileSize => _fileSize;
  String get filePath => _filePath ?? '';

  /// PDF 파일 로드
  Future<bool> loadPdf(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cleanupTempFile();
      _document?.dispose();

      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('파일을 찾을 수 없습니다', filePath);
      }

      _document = await PdfDocument.openFile(filePath);
      _filePath = filePath;
      _originalFilePath = filePath;
      _fileName = Uri.file(filePath).pathSegments.last;
      _fileSize = await FileService.getFileSize(filePath);
      _currentPage = 1;
      _zoom = 100;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _document = null;
      _filePath = null;
      _originalFilePath = '';
      _fileName = '';
      _fileSize = '';
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 현재 페이지 회전
  Future<void> rotateCurrentPage({required bool clockwise}) async {
    if (_document == null) return;

    final pageIndex = _currentPage - 1;
    final page = _document!.pages[pageIndex];
    final rotated = clockwise ? page.rotatedCW90() : page.rotatedCCW90();

    final newPages = List<PdfPage>.from(_document!.pages);
    newPages[pageIndex] = rotated;
    _document!.pages = newPages;

    // 임시 파일 저장 — PdfViewer가 회전된 버전을 로드하도록
    try {
      await _document!.assemble();
      final bytes = await _document!.encodePdf();
      final tempDir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/pdflibre_$stamp.pdf');
      await tempFile.writeAsBytes(bytes);

      _cleanupTempFile();
      _filePath = tempFile.path;
    } catch (_) {
      // 임시 파일 저장 실패 시에도 썸네일은 업데이트
    }

    notifyListeners();
  }

  /// 문서 닫기
  void closeDocument() {
    _cleanupTempFile();
    _document?.dispose();
    _document = null;
    _filePath = null;
    _originalFilePath = '';
    _fileName = '';
    _fileSize = '';
    _currentPage = 1;
    _zoom = 100;
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

  // === 줌 ===
  void setZoom(double zoom) {
    final clamped = zoom.clamp(25.0, 400.0);
    if (clamped != _zoom) {
      _zoom = clamped;
      notifyListeners();
    }
  }

  // === 뷰 모드 ===
  void setGridView(bool isGrid) {
    if (_isGridView != isGrid) {
      _isGridView = isGrid;
      notifyListeners();
    }
  }

  void _cleanupTempFile() {
    if (_filePath != null &&
        _originalFilePath.isNotEmpty &&
        _filePath != _originalFilePath) {
      try {
        File(_filePath!).deleteSync();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _cleanupTempFile();
    _document?.dispose();
    super.dispose();
  }
}
