import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// File picking and saving service
class FileService {
  static String? _lastDirectory;

  /// Extract directory from file path and update last used directory.
  /// p.dirname을 써야 Windows의 `\` 경로에서도 동작한다 (`/` split은
  /// Windows에서 항상 실패해 "마지막 폴더 기억"이 무력화됐다).
  static void _updateLastDirectory(String? path) {
    if (path == null || path.isEmpty) return;
    final dir = p.dirname(path);
    if (dir.isNotEmpty && dir != '.') {
      _lastDirectory = dir;
    }
  }

  /// PDF file picker dialog
  static Future<String?> pickPdfFile({String? dialogTitle}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: dialogTitle ?? 'PDF 파일 선택',
      initialDirectory: _lastDirectory,
    );
    final path = result?.files.single.path;
    _updateLastDirectory(path);
    return path;
  }

  /// Multiple PDF file picker dialog
  static Future<List<String>> pickMultiplePdfFiles({
    String? dialogTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      dialogTitle: dialogTitle ?? 'PDF 파일 선택',
      initialDirectory: _lastDirectory,
    );
    if (result == null) return [];
    final paths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
    if (paths.isNotEmpty) _updateLastDirectory(paths.first);
    return paths;
  }

  /// Pick save directory
  static Future<String?> pickSaveDirectory({String? dialogTitle}) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? '저장 위치 선택',
      initialDirectory: _lastDirectory,
    );
    if (dir != null) _lastDirectory = dir;
    return dir;
  }

  /// Pick save file path.
  ///
  /// [initialDirectoryOverride] is used when the user has configured a fixed
  /// save folder in settings. If that folder does not exist on disk, this
  /// gracefully falls back to the last-used directory (RF2 from the settings
  /// design review).
  static Future<String?> pickSaveFile({
    required String defaultName,
    String? extension,
    String? initialDirectoryOverride,
    String? dialogTitle,
  }) async {
    final initial = _resolveInitialDirectory(initialDirectoryOverride);
    final result = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle ?? '저장',
      fileName: defaultName,
      type: extension != null ? FileType.custom : FileType.any,
      allowedExtensions: extension != null ? [extension] : null,
      initialDirectory: initial,
    );
    _updateLastDirectory(result);
    return result;
  }

  /// Return [override] if it is a valid existing directory, otherwise fall
  /// back to the in-memory last-used directory. Returns null when neither
  /// is available so the OS picks its own default.
  static String? _resolveInitialDirectory(String? override) {
    if (override != null && override.isNotEmpty) {
      try {
        if (Directory(override).existsSync()) return override;
      } catch (e) {
        // Fall through to last-used directory.
        debugPrint('[PDFLibre] Fixed save folder check failed: $e');
      }
    }
    return _lastDirectory;
  }

  /// Format file size as a human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file size
  static Future<String> getFileSize(String filePath) async {
    final stat = await File(filePath).stat();
    return formatFileSize(stat.size);
  }
}
