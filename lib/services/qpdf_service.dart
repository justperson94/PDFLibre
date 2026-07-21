import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Wraps the bundled `qpdf` CLI to add or remove passwords on a PDF.
///
/// pdfrx exposes [PdfPasswordProvider] for reading encrypted PDFs but does
/// not provide any write-side encryption API, so we ship qpdf as a sidecar
/// binary inside each platform's release artifact and invoke it via
/// [Process.run].
///
/// Layout per platform (set by the release workflow):
///
///   macOS:   PDFLibre.app/Contents/Resources/qpdf
///   Windows: \[exe_dir]/data/qpdf.exe
///   Linux:   \[exe_dir]/qpdf
///
/// qpdf는 CI 릴리즈 빌드에만 번들되므로, 로컬 `flutter run`(디버그/프로필)
/// 에서는 번들 경로에 바이너리가 없다. 이 경우에만 시스템에 설치된 qpdf
/// (Homebrew/패키지 매니저 경로)로 폴백해 개발 중에도 암호 기능을 쓸 수
/// 있게 한다. 릴리즈 빌드는 번들 경로만 사용한다.
class QpdfService {
  QpdfService._();

  static String? _resolvedPath;
  static bool? _isAvailable;

  /// 번들 qpdf가 위치해야 할 경로 (릴리즈 아티팩트 기준).
  static String? get _bundledPath {
    final exe = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      // resolvedExecutable = ".../PDFLibre.app/Contents/MacOS/PDFLibre"
      final contents = p.dirname(p.dirname(exe));
      return p.join(contents, 'Resources', 'qpdf');
    } else if (Platform.isWindows) {
      return p.join(p.dirname(exe), 'data', 'qpdf.exe');
    } else if (Platform.isLinux) {
      return p.join(p.dirname(exe), 'qpdf');
    }
    return null;
  }

  /// 개발 빌드 전용: 시스템에 설치된 qpdf 후보 경로.
  static List<String> get _devFallbackPaths {
    if (Platform.isWindows) {
      return const [r'C:\Program Files\qpdf\bin\qpdf.exe'];
    }
    return const [
      '/opt/homebrew/bin/qpdf', // macOS (Apple Silicon Homebrew)
      '/usr/local/bin/qpdf', // macOS (Intel Homebrew) / Linux
      '/usr/bin/qpdf', // Linux 패키지 매니저
    ];
  }

  /// Absolute path to the qpdf binary, or null if not located.
  static String? get binaryPath {
    if (_resolvedPath != null) return _resolvedPath;
    final bundled = _bundledPath;
    if (bundled != null && File(bundled).existsSync()) {
      return _resolvedPath = bundled;
    }
    if (!kReleaseMode) {
      for (final candidate in _devFallbackPaths) {
        if (File(candidate).existsSync()) {
          debugPrint('[PDFLibre] Using system qpdf (dev fallback): $candidate');
          return _resolvedPath = candidate;
        }
      }
    }
    // 미발견 시 번들 기대 경로를 반환해 에러 메시지에 경로가 남게 한다.
    return _resolvedPath = bundled;
  }

  /// Returns true if the bundled binary exists and runs.
  ///
  /// 성공 결과만 캐시한다 — 첫 실행이 일시적으로 실패한 경우(예: Gatekeeper/
  /// AV 지연)를 음성으로 고착시키면 세션 내내 암호 기능이 잠기기 때문.
  static Future<bool> isAvailable() async {
    if (_isAvailable == true) return true;
    final path = binaryPath;
    if (path == null) return false;
    if (!File(path).existsSync()) return false;
    try {
      final result = await Process.run(path, ['--version']);
      if (result.exitCode == 0) return _isAvailable = true;
      debugPrint(
        '[PDFLibre] qpdf --version exited ${result.exitCode}: ${result.stderr}',
      );
      return false;
    } catch (e) {
      debugPrint('[PDFLibre] qpdf availability probe failed: $e');
      return false;
    }
  }

  /// Encrypt [inputPath] to [outputPath] with [userPassword].
  ///
  /// [ownerPassword] gates permission changes (printing, copying, etc.);
  /// if omitted it defaults to the user password so behaviour matches
  /// most consumer "password-protect" features.
  ///
  /// [currentPassword] is required when the input is already encrypted.
  /// Throws [QpdfException] on failure.
  static Future<void> setPassword({
    required String inputPath,
    required String outputPath,
    required String userPassword,
    String? ownerPassword,
    String? currentPassword,
  }) async {
    final owner = ownerPassword ?? userPassword;
    final args = <String>[
      if (currentPassword != null && currentPassword.isNotEmpty)
        '--password=$currentPassword',
      '--encrypt',
      userPassword,
      owner,
      '256',
      '--',
      inputPath,
      outputPath,
    ];
    await _run(args);
  }

  /// Decrypt [inputPath] to [outputPath] using [currentPassword].
  ///
  /// Throws [QpdfException] on failure (bad password, unsupported file).
  static Future<void> removePassword({
    required String inputPath,
    required String outputPath,
    required String currentPassword,
  }) async {
    final args = <String>[
      '--password=$currentPassword',
      '--decrypt',
      '--',
      inputPath,
      outputPath,
    ];
    await _run(args);
  }

  static Future<void> _run(List<String> args) async {
    final path = binaryPath;
    if (path == null) {
      throw const QpdfException(QpdfError.notFound, 'qpdf binary not located');
    }
    if (!File(path).existsSync()) {
      throw QpdfException(QpdfError.notFound, 'qpdf not found at $path');
    }
    // 인자에 평문 암호가 포함되므로 argv로 직접 넘기지 않는다 — 실행 중인
    // 프로세스의 argv는 같은 머신의 다른 사용자도 ps로 읽을 수 있다.
    // qpdf의 @argfile 문법(한 줄에 인자 하나)으로 전달하고, 파일은
    // mkdtemp(0700) 디렉토리에 두었다가 실행 직후 삭제한다.
    final tmpDir = await Directory.systemTemp.createTemp('pdflibre_qpdf_');
    try {
      final argFile = File(p.join(tmpDir.path, 'args'));
      await argFile.writeAsString(args.join('\n'));
      final result = await Process.run(path, ['@${argFile.path}']);
      // qpdf exit codes: 0 ok, 3 ok-with-warnings, anything else is an error.
      if (result.exitCode == 0 || result.exitCode == 3) return;
      final stderr = (result.stderr as String?)?.trim() ?? '';
      throw QpdfException(_classifyError(stderr), stderr);
    } finally {
      try {
        await tmpDir.delete(recursive: true);
      } catch (e) {
        debugPrint('[PDFLibre] qpdf argfile cleanup failed: $e');
      }
    }
  }

  static QpdfError _classifyError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid password') ||
        lower.contains('incorrect password')) {
      return QpdfError.badPassword;
    }
    if (lower.contains('no such file') || lower.contains('cannot open input')) {
      return QpdfError.inputMissing;
    }
    return QpdfError.unknown;
  }
}

enum QpdfError { notFound, badPassword, inputMissing, unknown }

class QpdfException implements Exception {
  const QpdfException(this.code, this.message);
  final QpdfError code;
  final String message;

  @override
  String toString() => 'QpdfException($code): $message';
}
