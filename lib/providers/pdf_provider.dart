import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import '../services/file_service.dart';

/// PDF 문서 상태 관리 프로바이더
class PdfProvider extends ChangeNotifier {
  PdfDocument? _document;
  Uint8List? _pdfBytes;
  int _version = 0;
  String _originalFilePath = '';
  String _fileName = '';
  String _fileSize = '';
  int _currentPage = 1;
  bool _isGridView = false;
  bool _isLoading = false;
  String? _error;

  // === Getters ===
  PdfDocument? get document => _document;
  Uint8List? get pdfBytes => _pdfBytes;
  int get version => _version;
  bool get hasDocument => _document != null;
  int get pageCount => _document?.pages.length ?? 0;
  int get currentPage => _currentPage;
  bool get isGridView => _isGridView;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fileName => _fileName;
  String get fileSize => _fileSize;
  String get originalFilePath => _originalFilePath;

  /// PDF 파일 로드
  Future<bool> loadPdf(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _document?.dispose();
      _document = null;

      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('파일을 찾을 수 없습니다', filePath);
      }

      // Dart가 파일을 바이트로 읽고, pdfium에 바이트를 직접 전달 (macOS 샌드박스 우회)
      final bytes = await file.readAsBytes();
      _document = await PdfDocument.openData(bytes, sourceName: filePath);
      _pdfBytes = bytes;
      _version++;
      _originalFilePath = filePath;
      _fileName = Uri.file(filePath).pathSegments.last;
      _fileSize = FileService.formatFileSize(bytes.length);
      _currentPage = 1;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _document = null;
      _pdfBytes = null;
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

    // 바이트 재생성 후 문서 재오픈 — 회전 상태 동기화
    try {
      await _document!.assemble();
      final bytes = await _document!.encodePdf();
      _document!.dispose();
      _version++;
      _document = await PdfDocument.openData(
        bytes,
        sourceName: '${_originalFilePath}_v$_version',
      );
      _pdfBytes = bytes;
    } catch (_) {
      _version++;
    }

    notifyListeners();
  }

  /// 문서 닫기
  void closeDocument() {
    _document?.dispose();
    _document = null;
    _pdfBytes = null;
    _originalFilePath = '';
    _fileName = '';
    _fileSize = '';
    _currentPage = 1;
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
    _document?.dispose();
    super.dispose();
  }
}
