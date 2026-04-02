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

  /// 페이지별 회전 각도 (0-indexed → 0, 90, 180, 270)
  final Map<int, int> _rotations = {};
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

  /// 특정 페이지의 회전 각도 반환
  int getPageRotation(int pageIndex) => _rotations[pageIndex] ?? 0;

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
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 현재 페이지 회전 (메타데이터만 변경, 뷰어는 디바운스 인코딩)
  void rotateCurrentPage({required bool clockwise}) {
    if (_document == null) return;

    final idx = _currentPage - 1;
    final current = _rotations[idx] ?? 0;
    final delta = clockwise ? 90 : -90;
    final newRotation = ((current + delta) % 360 + 360) % 360;

    if (newRotation == 0) {
      _rotations.remove(idx);
    } else {
      _rotations[idx] = newRotation;
    }

    _version++;
    notifyListeners();

    // 디바운스: 300ms 내 추가 회전 없으면 뷰어용 바이트 재생성
    _encodeTimer?.cancel();
    _encodeTimer = Timer(const Duration(milliseconds: 300), _rebuildViewerBytes);
  }

  /// 디바운스된 뷰어 바이트 재생성
  Future<void> _rebuildViewerBytes() async {
    if (_document == null || _originalPdfBytes == null) return;
    final versionAtStart = _version;

    if (_rotations.isEmpty) {
      // 회전 없으면 원본 바이트 사용
      if (!identical(_pdfBytes, _originalPdfBytes)) {
        _pdfBytes = _originalPdfBytes;
        _viewerVersion++;
        notifyListeners();
      }
      return;
    }

    try {
      final tempDoc = await PdfDocument.openData(
        _originalPdfBytes!,
        sourceName: 'temp_encode',
      );

      final newPages = List<PdfPage>.from(tempDoc.pages);
      for (final entry in _rotations.entries) {
        var page = newPages[entry.key];
        final turns = (entry.value % 360) ~/ 90;
        for (var t = 0; t < turns; t++) {
          page = page.rotatedCW90();
        }
        newPages[entry.key] = page;
      }
      tempDoc.pages = newPages;
      await tempDoc.assemble();
      final bytes = await tempDoc.encodePdf();
      tempDoc.dispose();

      // 인코딩 중 새 파일 로드 또는 추가 회전이 발생한 경우 결과 폐기
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
