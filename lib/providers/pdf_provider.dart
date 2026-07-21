import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import '../l10n/strings.dart';
import '../services/file_service.dart';
import '../utils/pdf_open_helper.dart';

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

  /// The password that successfully unlocked the current document, if any.
  /// Held in memory only — never persisted — so the secondary
  /// [PdfViewer.data] load that pdfrx performs in the body widget can
  /// supply the same password without prompting the user a second time.
  String? _password;

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

  /// True when the currently-loaded document required (and was unlocked
  /// with) a password.
  bool get isEncrypted => _password != null;

  /// The password that unlocked the current document, if any. In-memory
  /// only; surfaced to flows that need to re-encrypt or decrypt via the
  /// bundled qpdf binary.
  String? get currentPassword => _password;

  /// A PasswordProvider that immediately returns the cached password for the
  /// currently-loaded document, or null if the document was not encrypted.
  /// Use when handing the same bytes to a secondary pdfrx widget (e.g. the
  /// in-app viewer) that performs its own open call.
  PdfPasswordProvider? get viewerPasswordProvider {
    final pw = _password;
    if (pw == null) return null;
    return () => pw;
  }

  /// Original page index for a given display index
  int getOriginalPageIndex(int displayIndex) => _pageOrder[displayIndex];

  /// Returns rotation angle for a given display index
  int getPageRotation(int displayIndex) =>
      _rotations[_pageOrder[displayIndex]] ?? 0;

  /// Load a PDF file.
  ///
  /// [passwordProvider] is called when the PDF is encrypted; it returns the
  /// password to attempt, or null to abort. pdfrx will keep invoking the
  /// callback until it returns a working password or null.
  Future<bool> loadPdf(
    String filePath, {
    PdfPasswordProvider? passwordProvider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _encodeTimer?.cancel();
      _document?.dispose();
      _document = null;
      _password = null;

      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException(S.current.fileNotFound, filePath);
      }

      // Read file as bytes and pass directly to pdfium (bypasses macOS sandbox)
      final bytes = await file.readAsBytes();

      // Wrap the caller's PasswordProvider so we can capture the password
      // that successfully unlocked the document. pdfrx invokes the provider
      // in a loop until one of its returns works; after openData returns
      // we know the most recent non-null value is the correct one.
      String? candidatePassword;
      PdfPasswordProvider? captureProvider;
      if (passwordProvider != null) {
        captureProvider = () async {
          final value = await passwordProvider();
          candidatePassword = value;
          return value;
        };
      }
      _document = await PdfDocument.openData(
        bytes,
        sourceName: filePath,
        passwordProvider: captureProvider,
      );
      _password = candidatePassword;
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
      _password = null;
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
      '[PDFLibre] Rotate page ${originalPageIndex + 1} ${clockwise ? 'CW' : 'CCW'} 90° → $newRotation°',
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

    // 현재 페이지는 "몇 번째 표시 위치"가 아니라 "어느 원본 페이지"를 보고
    // 있는지가 기준이다. 다른 페이지가 현재 위치를 가로질러 이동해도 같은
    // 원본 페이지를 계속 가리키도록, 이동 전 원본 인덱스를 기억했다가
    // 이동 후 새 표시 위치를 되찾는다.
    final currentOriginal =
        (_currentPage >= 1 && _currentPage <= _pageOrder.length)
        ? _pageOrder[_currentPage - 1]
        : null;

    final item = _pageOrder.removeAt(oldDisplayIndex);
    _pageOrder.insert(newDisplayIndex, item);

    if (currentOriginal != null) {
      _currentPage = _pageOrder.indexOf(currentOriginal) + 1;
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

    PdfDocument? sourceDoc;
    PdfDocument? targetDoc;
    try {
      final cachedPassword = _password;
      sourceDoc = await PdfDocument.openData(
        _originalPdfBytes!,
        sourceName: 'temp_source',
        passwordProvider: cachedPassword == null ? null : () => cachedPassword,
      );
      targetDoc = await PdfDocument.createNew(sourceName: 'temp_target');

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

      if (_version != versionAtStart) return;

      _pdfBytes = bytes;
      _viewerVersion++;
      notifyListeners();
    } catch (e) {
      debugPrint('[PDFLibre] Rebuild viewer bytes failed: $e');
    } finally {
      // assemble()/encodePdf()가 던져도 네이티브 문서 핸들이 누수되지 않게
      // 성공/실패 공통 경로에서 해제한다.
      targetDoc?.dispose();
      sourceDoc?.dispose();
    }
  }

  /// Close document
  void closeDocument() {
    _encodeTimer?.cancel();
    // 진행 중인 _rebuildViewerBytes가 있다면 버전 가드에 걸려 결과를 버리게
    // 한다 — 닫힌 문서의 바이트가 _pdfBytes로 되살아나는 것을 방지.
    _version++;
    _document?.dispose();
    // Drop the cached unlock password for this file so reopening it later
    // (or by someone else on this machine) forces a fresh prompt.
    if (_originalFilePath.isNotEmpty) {
      PdfPasswordCache.remove(_originalFilePath);
    }
    _document = null;
    _pdfBytes = null;
    _originalPdfBytes = null;
    _password = null;
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
