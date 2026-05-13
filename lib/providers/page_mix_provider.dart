import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/page_mix.dart';
import '../models/pdf_file_info.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../utils/pdf_open_helper.dart';

/// Provider for the "페이지 혼합" merge mode.
///
/// Owns a list of loaded [SourcePdf]s, each with its own [PdfDocument] for
/// thumbnail rendering, per-source page selection, and the output queue of
/// [PageRef] instances that will be assembled into the merged PDF.
class PageMixProvider extends ChangeNotifier {
  final List<SourcePdf> _sources = [];
  final Map<String, PdfDocument> _documents = {};
  final Map<String, Set<int>> _selections = {};
  // Per-source anchor for Shift+Click range selection (Finder/Excel style).
  final Map<String, int> _anchors = {};
  final List<PageRef> _output = [];

  int _nextInstanceSeq = 1;
  int _sourcesAdded = 0;
  bool _isLoading = false;
  String? _error;

  // === Getters ===

  List<SourcePdf> get sources => List.unmodifiable(_sources);
  List<PageRef> get output => List.unmodifiable(_output);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOutput => _output.isNotEmpty;
  int get totalOutputPages => _output.length;

  PdfDocument? documentFor(String sourceId) => _documents[sourceId];

  SourcePdf? sourceById(String sourceId) {
    for (final s in _sources) {
      if (s.id == sourceId) return s;
    }
    return null;
  }

  Set<int> selectionFor(String sourceId) =>
      Set.unmodifiable(_selections[sourceId] ?? const <int>{});

  bool isSelected(String sourceId, int pageIndex) =>
      _selections[sourceId]?.contains(pageIndex) ?? false;

  /// Number of times this source page appears in the output queue.
  /// Duplicates are allowed (each instance has its own [PageRef.instanceId]),
  /// so this returns 0, 1, or more.
  int outputCountFor(String sourceId, int pageIndex) {
    var count = 0;
    for (final ref in _output) {
      if (ref.sourceId == sourceId && ref.pageIndex == pageIndex) count++;
    }
    return count;
  }

  /// Last-clicked page index used as the anchor for Shift+Click range selects.
  int? selectionAnchor(String sourceId) => _anchors[sourceId];

  // === Source management ===

  /// Load a PDF file and add it as a new source.
  ///
  /// Returns the new [SourcePdf] on success, or null on failure (error is
  /// set on [error]). Idempotent: loading a file already added is a no-op.
  ///
  /// [passwordProvider] is forwarded to pdfrx when the file is encrypted.
  Future<SourcePdf?> addSource(
    String filePath, {
    PdfPasswordProvider? passwordProvider,
  }) async {
    // Dedup: same file path → existing source
    final existing = _sources.where((s) => s.info.filePath == filePath);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('파일을 찾을 수 없습니다', filePath);
      }
      final bytes = await file.readAsBytes();
      final doc = await PdfDocument.openData(
        bytes,
        sourceName: filePath,
        passwordProvider: passwordProvider,
      );

      final id = filePath;
      final info = PdfFileInfo(
        filePath: filePath,
        fileName: Uri.file(filePath).pathSegments.last,
        fileSize: FileService.formatFileSize(bytes.length),
        pageCount: doc.pages.length,
      );
      final source = SourcePdf(
        id: id,
        info: info,
        colorTag: SourceColorPalette.forIndex(_sourcesAdded),
      );

      _sources.add(source);
      _documents[id] = doc;
      _selections[id] = <int>{};
      _sourcesAdded++;
      _isLoading = false;
      notifyListeners();
      return source;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Remove a source, its document, selection, and any output pages from it.
  void removeSource(String sourceId) {
    final removedIndex = _sources.indexWhere((s) => s.id == sourceId);
    if (removedIndex < 0) return;

    final removed = _sources[removedIndex];
    _documents[sourceId]?.dispose();
    _documents.remove(sourceId);
    _selections.remove(sourceId);
    _anchors.remove(sourceId);
    _sources.removeAt(removedIndex);
    _output.removeWhere((ref) => ref.sourceId == sourceId);
    PdfPasswordCache.remove(removed.info.filePath);
    notifyListeners();
  }

  // === Selection ===

  /// Cmd/Ctrl+Click: toggle a single page's selected state, anchoring on it.
  void togglePageSelection(String sourceId, int pageIndex) {
    final sel = _selections[sourceId];
    if (sel == null) return;
    if (!sel.remove(pageIndex)) sel.add(pageIndex);
    _anchors[sourceId] = pageIndex;
    notifyListeners();
  }

  /// Plain click: replace the selection with this single page and anchor here.
  void selectOnlyPage(String sourceId, int pageIndex) {
    final sel = _selections[sourceId];
    if (sel == null) return;
    sel
      ..clear()
      ..add(pageIndex);
    _anchors[sourceId] = pageIndex;
    notifyListeners();
  }

  /// Shift+Click: replace the selection with the inclusive range from the
  /// existing anchor to [targetIndex]. With no anchor yet, behaves like
  /// [selectOnlyPage]. The anchor itself does not move.
  void selectRangeFromAnchor(String sourceId, int targetIndex) {
    final sel = _selections[sourceId];
    if (sel == null) return;
    final anchor = _anchors[sourceId];
    if (anchor == null) {
      sel
        ..clear()
        ..add(targetIndex);
      _anchors[sourceId] = targetIndex;
    } else {
      final lo = anchor < targetIndex ? anchor : targetIndex;
      final hi = anchor < targetIndex ? targetIndex : anchor;
      sel
        ..clear()
        ..addAll(List.generate(hi - lo + 1, (i) => lo + i));
    }
    notifyListeners();
  }

  void selectAllPages(String sourceId) {
    final source = sourceById(sourceId);
    final sel = _selections[sourceId];
    if (source == null || sel == null) return;
    sel
      ..clear()
      ..addAll(List.generate(source.info.pageCount, (i) => i));
    notifyListeners();
  }

  void clearSelection(String sourceId) {
    final sel = _selections[sourceId];
    if (sel == null || sel.isEmpty) return;
    sel.clear();
    _anchors.remove(sourceId);
    notifyListeners();
  }

  /// Replace the selection with pages parsed from a 1-based range string
  /// like `"1-3, 5, 7-10"`. Throws on invalid input.
  void selectRange(String sourceId, String rangeText) {
    final source = sourceById(sourceId);
    final sel = _selections[sourceId];
    if (source == null || sel == null) return;
    final indices = PdfService.parsePageRange(
      rangeText,
      source.info.pageCount,
    );
    sel
      ..clear()
      ..addAll(indices);
    notifyListeners();
  }

  // === Output queue ===

  PageRef _makeRef(String sourceId, int pageIndex) {
    final id = 'p${_nextInstanceSeq++}';
    return PageRef(
      instanceId: id,
      sourceId: sourceId,
      pageIndex: pageIndex,
    );
  }

  /// Append a single page to the end of the output queue.
  /// Returns the created [PageRef].
  PageRef addPageToOutput(String sourceId, int pageIndex) {
    final ref = _makeRef(sourceId, pageIndex);
    _output.add(ref);
    notifyListeners();
    return ref;
  }

  /// Append all currently-selected pages (in page-index order) to the
  /// output queue. Selection is preserved.
  List<PageRef> addSelectionToOutput(String sourceId) {
    final sel = _selections[sourceId];
    if (sel == null || sel.isEmpty) return const [];
    final sorted = sel.toList()..sort();
    final added = <PageRef>[];
    for (final idx in sorted) {
      final ref = _makeRef(sourceId, idx);
      _output.add(ref);
      added.add(ref);
    }
    notifyListeners();
    return added;
  }

  /// Append all pages of the source (regardless of selection).
  List<PageRef> addAllPagesToOutput(String sourceId) {
    final source = sourceById(sourceId);
    if (source == null) return const [];
    final added = <PageRef>[];
    for (var i = 0; i < source.info.pageCount; i++) {
      final ref = _makeRef(sourceId, i);
      _output.add(ref);
      added.add(ref);
    }
    notifyListeners();
    return added;
  }

  /// Append pages parsed from a 1-based range string.
  List<PageRef> addRangeToOutput(String sourceId, String rangeText) {
    final source = sourceById(sourceId);
    if (source == null) return const [];
    final indices = PdfService.parsePageRange(
      rangeText,
      source.info.pageCount,
    );
    final added = <PageRef>[];
    for (final idx in indices) {
      final ref = _makeRef(sourceId, idx);
      _output.add(ref);
      added.add(ref);
    }
    notifyListeners();
    return added;
  }

  /// Remove a page instance from the output queue. Returns the removed ref
  /// and its former index, or null if the instance wasn't found (useful for
  /// Undo).
  ({PageRef ref, int index})? removeFromOutput(String instanceId) {
    final i = _output.indexWhere((r) => r.instanceId == instanceId);
    if (i < 0) return null;
    final removed = _output.removeAt(i);
    notifyListeners();
    return (ref: removed, index: i);
  }

  /// Insert a ref at [index]. If [index] is out of bounds, appends.
  void insertIntoOutput(int index, PageRef ref) {
    final clamped = index.clamp(0, _output.length);
    _output.insert(clamped, ref);
    notifyListeners();
  }

  /// Reorder a page within the output queue. Clamped to valid range.
  void reorderOutput(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _output.length) return;
    if (newIndex < 0 || newIndex > _output.length) return;
    if (oldIndex == newIndex) return;
    final ref = _output.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _output.insert(insertAt, ref);
    notifyListeners();
  }

  /// Rotate the output page in place. Does nothing if instance not found.
  void rotateOutput(String instanceId, {required bool clockwise}) {
    final i = _output.indexWhere((r) => r.instanceId == instanceId);
    if (i < 0) return;
    _output[i] = clockwise
        ? _output[i].rotatedClockwise()
        : _output[i].rotatedCounterClockwise();
    notifyListeners();
  }

  void clearOutput() {
    if (_output.isEmpty) return;
    _output.clear();
    notifyListeners();
  }

  /// Inject a source without loading a document. Test-only helper for
  /// exercising selection/output queue logic without PDF I/O.
  @visibleForTesting
  SourcePdf injectSourceForTest(SourcePdf source) {
    _sources.add(source);
    _selections[source.id] = <int>{};
    _sourcesAdded++;
    notifyListeners();
    return source;
  }

  /// Remove all sources, selections, and the output queue.
  void reset() {
    for (final doc in _documents.values) {
      doc.dispose();
    }
    for (final source in _sources) {
      PdfPasswordCache.remove(source.info.filePath);
    }
    _documents.clear();
    _sources.clear();
    _selections.clear();
    _output.clear();
    _sourcesAdded = 0;
    _nextInstanceSeq = 1;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final doc in _documents.values) {
      doc.dispose();
    }
    for (final source in _sources) {
      PdfPasswordCache.remove(source.info.filePath);
    }
    super.dispose();
  }
}
