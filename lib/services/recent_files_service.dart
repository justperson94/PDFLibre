import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Manages recently opened file paths (max 10, stored as JSON)
class RecentFilesService {
  static const _maxFiles = 10;
  static const _fileName = 'recent_files.json';

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
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(String filePath) async {
    final list = await load();
    list.remove(filePath);
    list.insert(0, filePath);
    if (list.length > _maxFiles) {
      list.removeRange(_maxFiles, list.length);
    }
    final file = await _getFile();
    await file.writeAsString(jsonEncode(list));
  }

  /// Remove a single file from the recent list (e.g., when it became inaccessible)
  static Future<void> remove(String filePath) async {
    final list = await load();
    if (!list.remove(filePath)) return;
    final file = await _getFile();
    await file.writeAsString(jsonEncode(list));
  }
}
