import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import '../services/file_service.dart';

/// Provider for managing PDF document state
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

  /// Rotation angle per page (original page index -> 0, 90, 180, 270)
  final Map<int, int> _rotations = {};

  /// Page display order (display index -> original page index)
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

  /// Original page index for a given display index
  int getOriginalPageIndex(int displayIndex) => _pageOrder[displayIndex];

  /// Returns rotation angle for a given display index
  int getPageRotation(int displayIndex) =>
      _rotations[_pageOrder[displayIndex]] ?? 0;

  /// Load a PDF file
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

      // Read file as bytes and pass directly to pdfium (bypasses macOS sandbox)
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

  /// Apply page rotation (for command system, based on original page index)
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
    debugPrint(
      '[PDFLibre] Rotate page ${originalPageIndex + 1} ${clockwise ? 'CW' : 'CCW'} 90° → ${newRotation}°',
    );
    notifyListeners();
    _scheduleRebuild();
  }

  /// Apply page reorder (for command system, based on display index)
  void applyReorder(int oldDisplayIndex, int newDisplayIndex) {
    if (_document == null) return;
    if (oldDisplayIndex == newDisplayIndex) return;
    if (oldDisplayIndex < 0 || oldDisplayIndex >= _pageOrder.length) return;
    if (newDisplayIndex < 0 || newDisplayIndex >= _pageOrder.length) return;

    final item = _pageOrder.removeAt(oldDisplayIndex);
    _pageOrder.insert(newDisplayIndex, item);

    // Follow the moved page if it was the current page
    if (_currentPage == oldDisplayIndex + 1) {
      _currentPage = newDisplayIndex + 1;
    }

    _version++;
    debugPrint(
      '[PDFLibre] Reorder page ${oldDisplayIndex + 1} → ${newDisplayIndex + 1}',
    );
    notifyListeners();
    _scheduleRebuild();
  }

  /// Schedule debounced viewer bytes rebuild
  void _scheduleRebuild() {
    _encodeTimer?.cancel();
    _encodeTimer = Timer(
      const Duration(milliseconds: 300),
      _rebuildViewerBytes,
    );
  }

  /// Check if page order is the default order
  bool get _isDefaultOrder {
    for (var i = 0; i < _pageOrder.length; i++) {
      if (_pageOrder[i] != i) return false;
    }
    return true;
  }

  /// Debounced viewer bytes rebuild
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
      debugPrint('[PDFLibre] Rebuild viewer bytes failed: $e');
    }
  }

  /// Close document
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

  // === Page navigation ===
  void setPage(int page) {
    if (page >= 1 && page <= pageCount && page != _currentPage) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void nextPage() => setPage(_currentPage + 1);
  void prevPage() => setPage(_currentPage - 1);

  // === View mode ===
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
