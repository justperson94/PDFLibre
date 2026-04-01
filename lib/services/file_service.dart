import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// 파일 선택 및 저장 서비스
class FileService {
  /// PDF 파일 선택 다이얼로그
  static Future<String?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'PDF 파일 선택',
    );
    return result?.files.single.path;
  }

  /// 여러 PDF 파일 선택 다이얼로그
  static Future<List<String>> pickMultiplePdfFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      dialogTitle: 'PDF 파일 선택',
    );
    if (result == null) return [];
    return result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
  }

  /// 저장 디렉토리 선택
  static Future<String?> pickSaveDirectory() async {
    return FilePicker.platform.getDirectoryPath(dialogTitle: '저장 위치 선택');
  }

  /// 저장 파일 경로 선택
  static Future<String?> pickSaveFile({
    required String defaultName,
    String? extension,
  }) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '저장',
      fileName: defaultName,
      type: extension != null ? FileType.custom : FileType.any,
      allowedExtensions: extension != null ? [extension] : null,
    );
    return result;
  }

  /// 파일 크기를 읽기 쉬운 문자열로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 파일 크기 조회
  static Future<String> getFileSize(String filePath) async {
    final stat = await File(filePath).stat();
    return formatFileSize(stat.size);
  }
}
