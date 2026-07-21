import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages recently opened file paths (max 10, stored as JSON)
class RecentFilesService {
  static const _maxFiles = 10;
  static const _fileName = 'recent_files.json';

  /// add/remove는 read-modify-write이므로 동시에 실행되면 나중 쓰기가 앞선
  /// 쓰기를 덮어 항목이 유실된다. Future 체인으로 변경 작업을 직렬화한다.
  static Future<void> _writeQueue = Future.value();

  static Future<void> _enqueue(Future<void> Function() op) {
    final result = _writeQueue.then((_) => op());
    // 큐 자체는 실패해도 계속 진행되도록 에러를 삼키되 로그는 남긴다.
    _writeQueue = result.catchError(
      (Object e) => debugPrint('[PDFLibre] Recent files update failed: $e'),
    );
    return result;
  }

  static Future<File> _getFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<String>> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final json = await file.readAsString();
      final list = (jsonDecode(json) as List).cast<String>();
      // Filter out files that no longer exist
      final existing = <String>[];
      for (final path in list) {
        if (await File(path).exists()) {
          existing.add(path);
        }
      }
      return existing;
    } catch (e) {
      // 손상된 목록은 빈 목록으로 복구하되, 원인은 로그로 남긴다.
      debugPrint('[PDFLibre] Failed to load recent files: $e');
      return [];
    }
  }

  static Future<void> add(String filePath) {
    return _enqueue(() async {
      final list = await load();
      list.remove(filePath);
      list.insert(0, filePath);
      if (list.length > _maxFiles) {
        list.removeRange(_maxFiles, list.length);
      }
      final file = await _getFile();
      await file.writeAsString(jsonEncode(list));
    });
  }

  /// Remove a single file from the recent list (e.g., when it became inaccessible)
  static Future<void> remove(String filePath) {
    return _enqueue(() async {
      final list = await load();
      if (!list.remove(filePath)) return;
      final file = await _getFile();
      await file.writeAsString(jsonEncode(list));
    });
  }
}
